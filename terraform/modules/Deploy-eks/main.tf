#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_roles" "admin_role" {
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "network_role" {
  name_regex  = "AWSReservedSSO_NetworkAdministrator_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

locals {
  access_entries = flatten([
    for group_name, config in var.eks.access_entries : [
      for principal_arn in config.principal_arns : {
        key               = "${group_name}-${principal_arn}"
        principal_arn     = principal_arn
        policy_arn        = config.policy_arn
        kubernetes_groups = config.kubernetes_groups
      }
    ]
  ])

  access_entries_map = { for entry in local.access_entries : entry.key => entry }
  # Filtered map — only entries that have a policy_arn
  access_policies_map = {
    for k, v in local.access_entries_map : k => v
    if v.policy_arn != null && v.policy_arn != ""
  }

  admin_role_arn               = length(data.aws_iam_roles.admin_role.arns) > 0 ? sort(data.aws_iam_roles.admin_role.arns)[0] : ""
  network_role_arn             = length(data.aws_iam_roles.network_role.arns) > 0 ? sort(data.aws_iam_roles.network_role.arns)[0] : ""
  created_service_account_keys = var.eks.create_service_accounts && var.eks.service_accounts != null ? toset([for sa in var.eks.service_accounts : sa.key]) : toset([])
  system_node_selector = {
    "workload-type" = "system"
  }
  system_tolerations = [{
    key      = "workload-type"
    operator = "Equal"
    value    = "system"
    effect   = "NoSchedule"
    }
  ]
  all_workload_node_tolerations = [{
    operator = "Exists"
  }]

  # Spreads replicated system controllers across the AZs the system node group spans.
  # ScheduleAnyway rather than DoNotSchedule so a single-AZ capacity shortage degrades
  # spreading instead of leaving cluster-critical pods Pending.
  system_topology_spread_base = {
    maxSkew           = 1
    topologyKey       = "topology.kubernetes.io/zone"
    whenUnsatisfiable = "ScheduleAnyway"
  }

  karpenter_enabled = var.eks.compute.karpenter.enabled && var.eks.compute.create_node_group
  karpenter         = local.karpenter_enabled ? var.eks.compute.karpenter : null

  karpenter_interruption_queue_name = local.karpenter_enabled ? coalesce(local.karpenter.interruption_queue_name, aws_eks_cluster.eks_cluster.name) : null

  karpenter_controller_role_arn = local.karpenter_enabled ? (
    local.karpenter.controller_role_key != null ? module.iam_roles[local.karpenter.controller_role_key].iam_role_arn : local.karpenter.controller_role_arn
  ) : null

  karpenter_node_role_arn = local.karpenter_enabled ? (
    local.karpenter.node_role_key != null ? module.iam_roles[local.karpenter.node_role_key].iam_role_arn : local.karpenter.node_role_arn
  ) : null

  karpenter_node_role_name = local.karpenter_enabled ? coalesce(
    local.karpenter.node_role_name,
    local.karpenter.node_role_key != null ? module.iam_roles[local.karpenter.node_role_key].aws_iam_role_name : null,
    local.karpenter.node_role_arn != null ? element(split("/", local.karpenter.node_role_arn), length(split("/", local.karpenter.node_role_arn)) - 1) : null
  ) : null

  eks_node_group_role_input_arns = [
    for node_group in try(var.eks.compute.eks_node_groups, []) : node_group.node_role_arn
    if try(node_group.node_role_arn, null) != null
  ]

  eks_node_group_role_keys = [
    for node_group in try(var.eks.compute.eks_node_groups, []) : node_group.node_role_key
    if try(node_group.node_role_key, null) != null
  ]

  karpenter_node_role_input_arn = local.karpenter_enabled ? try(local.karpenter.node_role_arn, null) : null
  karpenter_node_role_input_key = local.karpenter_enabled ? try(local.karpenter.node_role_key, null) : null

  karpenter_node_role_matches_node_group = local.karpenter_enabled && (
    (local.karpenter_node_role_input_arn != null ? contains(local.eks_node_group_role_input_arns, local.karpenter_node_role_input_arn) : false) ||
    (local.karpenter_node_role_input_key != null ? contains(local.eks_node_group_role_keys, local.karpenter_node_role_input_key) : false)
  )

  create_karpenter_node_access_entry = local.karpenter_enabled && !local.karpenter_node_role_matches_node_group

  karpenter_interruption_events = {
    spot_interruption = {
      source      = ["aws.ec2"]
      detail-type = ["EC2 Spot Instance Interruption Warning"]
    }
    rebalance_recommendation = {
      source      = ["aws.ec2"]
      detail-type = ["EC2 Instance Rebalance Recommendation"]
    }
    instance_state_change = {
      source      = ["aws.ec2"]
      detail-type = ["EC2 Instance State-change Notification"]
    }
    health_event = {
      source      = ["aws.health"]
      detail-type = ["AWS Health Event"]
    }
  }
  karpenter_manifests_yaml = local.karpenter_enabled && try(local.karpenter.nodepool_manifest_file, null) != null ? replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    file(local.karpenter.nodepool_manifest_file),
                    "[[account_number]]", data.aws_caller_identity.current.account_id
                  ),
                  "[[account_name]]", var.common.account_name
                ),
                "[[environment_abr]]", var.common.environment_abr
              ),
              "[[account_name_abr]]", var.common.account_name_abr
            ),
            "[[region]]", data.aws_region.current.name
          ),
          "[[region_prefix]]", var.common.region_prefix
        ),
        "[[cluster_name]]", aws_eks_cluster.eks_cluster.name
      ),
      "[[node_role_name]]", coalesce(local.karpenter_node_role_name, "")
    ),
    "[[node_role_arn]]", coalesce(local.karpenter_node_role_arn, "")
  ) : null
  karpenter_manifest_documents = local.karpenter_manifests_yaml != null ? [
    for document in split("\n---\n", local.karpenter_manifests_yaml) : trimspace(document)
    if trimspace(document) != ""
  ] : []

  nginx_ingress_defaults = {
    replica_count = 2
    timeout       = 900
    scheme        = "internet-facing"
    target_type   = "ip"
    ssl_cert_arn  = null
    ssl_policy    = null
    ssl_ports     = []
  }
  gateway_api_defaults = {
    version                  = "2.6.7"
    release_name             = "ngf"
    namespace                = "nginx-gateway"
    gateway_class_name       = "nginx"
    controller_name          = "gateway.nginx.org/nginx-gateway-controller"
    nginx_replicas           = 2
    fabric_replicas          = 1
    scheme                   = "internet-facing"
    target_type              = "ip"
    nlb_name                 = null
    ssl_cert_arn             = null
    ssl_policy               = null
    ssl_ports                = []
    subnet_ids               = []
    security_group_keys      = []
    security_group_ids       = []
    service_annotations      = {}
    service_annotations_file = null
    values                   = []
  }

  ingress_enabled     = var.eks.ingress.enabled && var.eks.compute.create_node_group
  nginx_ingress_input = local.ingress_enabled ? var.eks.ingress.nginx : []
  gateway_api_input = {
    version                  = try(var.eks.ingress.gateway_api.version, local.gateway_api_defaults.version)
    release_name             = try(var.eks.ingress.gateway_api.release_name, local.gateway_api_defaults.release_name)
    namespace                = try(var.eks.ingress.gateway_api.namespace, local.gateway_api_defaults.namespace)
    gateway_class_name       = try(var.eks.ingress.gateway_api.gateway_class_name, local.gateway_api_defaults.gateway_class_name)
    controller_name          = try(var.eks.ingress.gateway_api.controller_name, local.gateway_api_defaults.controller_name)
    nginx_replicas           = try(var.eks.ingress.gateway_api.nginx_replicas, local.gateway_api_defaults.nginx_replicas)
    fabric_replicas          = try(var.eks.ingress.gateway_api.fabric_replicas, local.gateway_api_defaults.fabric_replicas)
    scheme                   = try(var.eks.ingress.gateway_api.scheme, local.gateway_api_defaults.scheme)
    target_type              = try(var.eks.ingress.gateway_api.target_type, local.gateway_api_defaults.target_type)
    nlb_name                 = try(var.eks.ingress.gateway_api.nlb_name, local.gateway_api_defaults.nlb_name)
    subnet_ids               = try(var.eks.ingress.gateway_api.subnet_ids, local.gateway_api_defaults.subnet_ids)
    security_group_keys      = try(var.eks.ingress.gateway_api.security_group_keys, local.gateway_api_defaults.security_group_keys)
    security_group_ids       = try(var.eks.ingress.gateway_api.security_group_ids, local.gateway_api_defaults.security_group_ids)
    service_annotations      = try(var.eks.ingress.gateway_api.service_annotations, local.gateway_api_defaults.service_annotations)
    service_annotations_file = try(var.eks.ingress.gateway_api.service_annotations_file, local.gateway_api_defaults.service_annotations_file)
    values                   = try(var.eks.ingress.gateway_api.values, local.gateway_api_defaults.values)
  }
  nginx_ingress_enabled = local.ingress_enabled && length(local.nginx_ingress_input) > 0
  gateway_api_enabled   = local.ingress_enabled && try(var.eks.ingress.gateway_api, null) != null

  ingress_config = local.ingress_enabled ? merge(
    {
      gateway_api = local.gateway_api_defaults
    },
    {
      nginx       = var.eks.ingress.nginx
      gateway_api = var.eks.ingress.gateway_api
    },
    {
      gateway_api = merge(
        local.gateway_api_defaults,
        local.gateway_api_input
      )
    }
  ) : null

  nginx_ingress_configs = local.nginx_ingress_enabled ? [
    for ingress in local.nginx_ingress_input : merge(
      local.nginx_ingress_defaults,
      ingress,
      {
        release_name       = coalesce(ingress.release_name, ingress.name)
        namespace          = coalesce(ingress.namespace, "ingress-${ingress.name}")
        ingress_class_name = coalesce(ingress.ingress_class_name, ingress.name)
      }
    )
  ] : []
  nginx_ingress_security_group_ids = {
    for ingress in local.nginx_ingress_configs : ingress.name => concat(
      [
        for sg_key in try(ingress.security_group_keys, []) :
        sg_key == "eks_cluster_sg_id" ? aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id : module.security_group[sg_key].security_group_id
      ],
      try(ingress.security_group_ids, [])
    )
  }
  nginx_ingress_tls_secret_map = {
    for ingress in local.nginx_ingress_configs : ingress.name => merge(
      ingress.tls_secret,
      {
        namespace = coalesce(try(ingress.tls_secret.namespace, null), ingress.namespace)
      }
    ) if try(ingress.tls_secret, null) != null
  }
  nginx_ingress_map = {
    for ingress in local.nginx_ingress_configs : ingress.name => ingress
  }
  nginx_ingress_service_annotations = {
    for ingress in local.nginx_ingress_configs : ingress.name => merge(
      {
        "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
        "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = ingress.target_type
        "service.beta.kubernetes.io/aws-load-balancer-scheme"          = ingress.scheme
      },
      length(ingress.subnet_ids) > 0 ? {
        "service.beta.kubernetes.io/aws-load-balancer-subnets" = join(",", ingress.subnet_ids)
      } : {},
      length(local.nginx_ingress_security_group_ids[ingress.name]) > 0 ? {
        "service.beta.kubernetes.io/aws-load-balancer-security-groups" = join(",", local.nginx_ingress_security_group_ids[ingress.name])
      } : {},
      ingress.ssl_cert_arn != null ? {
        "service.beta.kubernetes.io/aws-load-balancer-ssl-cert" = ingress.ssl_cert_arn
      } : {},
      ingress.ssl_policy != null ? {
        "service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy" = ingress.ssl_policy
      } : {},
      length(ingress.ssl_ports) > 0 ? {
        "service.beta.kubernetes.io/aws-load-balancer-ssl-ports" = join(",", ingress.ssl_ports)
      } : {},
      ingress.nlb_name != null ? {
        "service.beta.kubernetes.io/aws-load-balancer-name" = ingress.nlb_name
      } : {},
      try(ingress.service_annotations_file, null) != null ? yamldecode(file(ingress.service_annotations_file)) : {},
      ingress.service_annotations
    )
  }

  gateway_api_config = local.gateway_api_enabled ? local.ingress_config.gateway_api : null
  gateway_api_security_group_ids = local.gateway_api_enabled ? concat(
    [
      for sg_key in try(local.gateway_api_config.security_group_keys, []) :
      sg_key == "eks_cluster_sg_id" ? aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id : module.security_group[sg_key].security_group_id
    ],
    try(local.gateway_api_config.security_group_ids, [])
  ) : []
  gateway_api_service_annotations = local.gateway_api_enabled ? merge(
    {
      "service.beta.kubernetes.io/aws-load-balancer-type"            = "external"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = local.gateway_api_config.target_type
      "service.beta.kubernetes.io/aws-load-balancer-scheme"          = local.gateway_api_config.scheme
    },
    length(local.gateway_api_config.subnet_ids) > 0 ? {
      "service.beta.kubernetes.io/aws-load-balancer-subnets" = join(",", local.gateway_api_config.subnet_ids)
    } : {},
    length(local.gateway_api_security_group_ids) > 0 ? {
      "service.beta.kubernetes.io/aws-load-balancer-security-groups" = join(",", local.gateway_api_security_group_ids)
    } : {},
    local.gateway_api_config.ssl_cert_arn != null ? {
      "service.beta.kubernetes.io/aws-load-balancer-ssl-cert" = local.gateway_api_config.ssl_cert_arn
    } : {},
    local.gateway_api_config.ssl_policy != null ? {
      "service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy" = local.gateway_api_config.ssl_policy
    } : {},
    length(local.gateway_api_config.ssl_ports) > 0 ? {
      "service.beta.kubernetes.io/aws-load-balancer-ssl-ports" = join(",", local.gateway_api_config.ssl_ports)
    } : {},
    local.gateway_api_config.nlb_name != null ? {
      "service.beta.kubernetes.io/aws-load-balancer-name" = local.gateway_api_config.nlb_name
    } : {},
    try(local.gateway_api_config.service_annotations_file, null) != null ? yamldecode(file(local.gateway_api_config.service_annotations_file)) : {},
    local.gateway_api_config.service_annotations
  ) : {}

  argocd_enabled         = var.eks.ingress.argocd.enabled && var.eks.compute.create_node_group
  argocd_ingress_enabled = local.argocd_enabled && var.eks.ingress.argocd.ingress_enabled

  argocd_ingress_security_group_ids = local.argocd_enabled ? concat(
    [
      for sg_key in var.eks.ingress.argocd.ingress_security_group_keys :
      sg_key == "eks_cluster_sg_id" ? aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id : module.security_group[sg_key].security_group_id
    ],
    var.eks.ingress.argocd.ingress_security_group_ids
  ) : []

  argocd_ingress_annotations = local.argocd_ingress_enabled ? merge(
    {
      "alb.ingress.kubernetes.io/scheme"           = var.eks.ingress.argocd.ingress_scheme
      "alb.ingress.kubernetes.io/target-type"      = var.eks.ingress.argocd.ingress_target_type
      "alb.ingress.kubernetes.io/backend-protocol" = var.eks.ingress.argocd.server_insecure ? "HTTP" : "HTTPS"
      "alb.ingress.kubernetes.io/listen-ports" = var.eks.ingress.argocd.certificate_arn != null ? jsonencode([
        { HTTP = 80 }, { HTTPS = 443 }
      ]) : jsonencode([{ HTTP = 80 }])
      "alb.ingress.kubernetes.io/healthcheck-path" = "/healthz"
    },
    var.eks.ingress.argocd.certificate_arn != null ? {
      "alb.ingress.kubernetes.io/certificate-arn" = var.eks.ingress.argocd.certificate_arn
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
    } : {},
    var.eks.ingress.argocd.ssl_policy != null ? {
      "alb.ingress.kubernetes.io/ssl-policy" = var.eks.ingress.argocd.ssl_policy
    } : {},
    var.eks.ingress.argocd.ingress_group_name != null ? {
      "alb.ingress.kubernetes.io/group.name" = var.eks.ingress.argocd.ingress_group_name
    } : {},
    var.eks.ingress.argocd.alb_name != null ? {
      "alb.ingress.kubernetes.io/load-balancer-name" = var.eks.ingress.argocd.alb_name
    } : {},
    length(var.eks.ingress.argocd.ingress_subnet_ids) > 0 ? {
      "alb.ingress.kubernetes.io/subnets" = join(",", var.eks.ingress.argocd.ingress_subnet_ids)
    } : {},
    length(local.argocd_ingress_security_group_ids) > 0 ? {
      "alb.ingress.kubernetes.io/security-groups" = join(",", local.argocd_ingress_security_group_ids)
    } : {},
    try(var.eks.ingress.argocd.ingress_annotations_file, null) != null ? yamldecode(file(var.eks.ingress.argocd.ingress_annotations_file)) : {},
    var.eks.ingress.argocd.ingress_annotations
  ) : {}

  cert_manager_route53_role_arn = (
    var.eks.addons.cert_manager.route53_role_key != null
    ? module.iam_roles[var.eks.addons.cert_manager.route53_role_key].iam_role_arn
    : var.eks.addons.cert_manager.route53_role_arn
  )
}
#--------------------------------------------------------------------
# EKS Cluster
#--------------------------------------------------------------------
resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.name}-eks-cluster"
  role_arn = var.eks.role_arn

  vpc_config {
    subnet_ids = var.eks.subnet_ids
    security_group_ids = concat(
      var.eks.additional_security_group_ids,
      [for key in var.eks.additional_security_group_keys : module.security_group[key].security_group_id]
    )
    endpoint_private_access = var.eks.endpoint_private_access
    endpoint_public_access  = var.eks.endpoint_public_access
    public_access_cidrs     = var.eks.public_access_cidrs
  }

  access_config {
    authentication_mode                         = var.eks.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.eks.bootstrap_cluster_creator_admin_permissions
  }
  # NOTE: compute/ingress/addons groups configured below govern node groups, ingress controllers, and cluster addons.

  kubernetes_network_config {
    service_ipv4_cidr = var.eks.service_ipv4_cidr
  }

  enabled_cluster_log_types = var.eks.enabled_cluster_log_types

  version = var.eks.version
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.name}-eks-cluster"
  })
}

#--------------------------------------------------------------------
# EKS Access Entry and Policy Association
#--------------------------------------------------------------------
resource "aws_eks_access_entry" "access_entry" {
  for_each = local.access_entries_map

  cluster_name      = aws_eks_cluster.eks_cluster.name
  principal_arn     = each.value.principal_arn
  type              = "STANDARD"
  kubernetes_groups = length(each.value.kubernetes_groups) > 0 ? each.value.kubernetes_groups : null
}

resource "aws_eks_access_policy_association" "access_policy" {
  for_each = local.access_policies_map

  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.access_entry]
}

#--------------------------------------------------------------------
# OIDC Provider for EKS Cluster
#--------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [var.eks.oidc_thumbprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

#--------------------------------------------------------------------
# EKS Addons - Tier 1: Core Networking (Install First)
#--------------------------------------------------------------------
resource "aws_eks_addon" "vpc_cni" {
  count                       = var.eks.addons.vpc_cni.enabled ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "vpc-cni"
  addon_version               = var.eks.addons.vpc_cni.version
  resolve_conflicts_on_update = "PRESERVE"
  configuration_values = jsonencode({
    for k, v in merge(
      { tolerations = local.all_workload_node_tolerations },
      var.eks.addons.vpc_cni.enable_prefix_delegation ? {
        enableNetworkPolicy = "true"
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = tostring(var.eks.addons.vpc_cni.warm_prefix_target)
        }
        } : {
        enableNetworkPolicy = null
        env                 = null
      }
    ) : k => v if v != null
  })

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.key}-vpc-cni-addon"
  })
}

resource "aws_eks_addon" "kube_proxy" {
  count                       = var.eks.addons.kube_proxy.enabled ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "kube-proxy"
  addon_version               = var.eks.addons.kube_proxy.version
  resolve_conflicts_on_update = "PRESERVE"
  # No configuration_values here on purpose: the kube-proxy addon's
  # configurationValues JSON schema doesn't accept a "tolerations" key at
  # all (AWS rejects it with a schema validation error on create, unlike
  # vpc-cni, which does support it). kube-proxy's own default manifest
  # already tolerates every taint unconditionally, so it needs no override
  # to run on every node - including the tainted system node group.

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.key}-kube-proxy-addon"
  })
}

#--------------------------------------------------------------------
# EKS Addons - Tier 2: After Node Groups
#--------------------------------------------------------------------
resource "aws_eks_addon" "coredns" {
  count                       = var.eks.addons.coredns.enabled && var.eks.compute.create_node_group ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "coredns"
  addon_version               = var.eks.addons.coredns.version
  resolve_conflicts_on_update = "PRESERVE"
  configuration_values        = jsonencode({ nodeSelector = local.system_node_selector, tolerations = local.system_tolerations })

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.key}-coredns-addon"
  })
  depends_on = [
    module.eks_node_group,
    aws_eks_addon.vpc_cni,
    aws_eks_addon.kube_proxy
  ]
}

resource "aws_eks_addon" "pod_identity_agent" {
  count                       = var.eks.addons.pod_identity_agent.enabled && var.eks.compute.create_node_group ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = var.eks.addons.pod_identity_agent.version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  configuration_values        = jsonencode({ tolerations = local.all_workload_node_tolerations })

  depends_on = [
    module.eks_node_group,
    aws_eks_addon.vpc_cni,
    aws_eks_addon.kube_proxy
  ]
}

#--------------------------------------------------------------------
# EKS Addons - Tier 3: Infrastructure Controllers
#--------------------------------------------------------------------
resource "aws_eks_addon" "ebs_csi_driver" {
  count                    = var.eks.addons.ebs_csi_driver.enabled && var.eks.compute.create_node_group ? 1 : 0
  cluster_name             = aws_eks_cluster.eks_cluster.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.eks.addons.ebs_csi_driver.version
  service_account_role_arn = var.eks.addons.ebs_csi_driver.role_key != null ? module.iam_roles[var.eks.addons.ebs_csi_driver.role_key].iam_role_arn : var.eks.addons.ebs_csi_driver.role_arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  configuration_values = jsonencode({
    controller = {
      nodeSelector = local.system_node_selector
      tolerations  = local.system_tolerations
      topologySpreadConstraints = [
        merge(local.system_topology_spread_base, {
          labelSelector = {
            matchLabels = {
              app = "ebs-csi-controller"
            }
          }
        })
      ]
    }
    node = { tolerations = local.all_workload_node_tolerations }
  })

  depends_on = [
    module.eks_node_group,
    module.iam_roles,
    aws_eks_addon.coredns,
    aws_eks_addon.pod_identity_agent
  ]
}

#--------------------------------------------------------------------
# GP3 Storage Class for EBS CSI Driver
#--------------------------------------------------------------------
resource "kubernetes_storage_class_v1" "gp3" {
  count = var.eks.addons.ebs_csi_driver.enabled && var.eks.compute.create_node_group ? 1 : 0
  metadata {
    name = "gp3"
  }
  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true
  parameters = {
    type   = "gp3"
    fsType = "ext4"
  }
  depends_on = [
    aws_eks_addon.ebs_csi_driver
  ]
}

#--------------------------------------------------------------------
# EFS CSI Driver
#--------------------------------------------------------------------
resource "aws_eks_addon" "efs_csi_driver" {
  count                    = var.eks.addons.efs_csi_driver.enabled && var.eks.compute.create_node_group ? 1 : 0
  cluster_name             = aws_eks_cluster.eks_cluster.name
  addon_name               = "aws-efs-csi-driver"
  addon_version            = var.eks.addons.efs_csi_driver.version
  service_account_role_arn = var.eks.addons.efs_csi_driver.role_key != null ? module.iam_roles[var.eks.addons.efs_csi_driver.role_key].iam_role_arn : var.eks.addons.efs_csi_driver.role_arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  configuration_values = jsonencode({
    controller = {
      nodeSelector = local.system_node_selector
      tolerations  = local.system_tolerations
      topologySpreadConstraints = [
        merge(local.system_topology_spread_base, {
          labelSelector = {
            matchLabels = {
              app = "efs-csi-controller"
            }
          }
        })
      ]
    }
    node = { tolerations = local.all_workload_node_tolerations }
  })

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.key}-efs-csi-driver-addon"
  })

  depends_on = [
    module.eks_node_group,
    module.iam_roles,
    aws_eks_addon.coredns,
    aws_eks_addon.pod_identity_agent
  ]
}

#--------------------------------------------------------------------
# FSx CSI Driver
#--------------------------------------------------------------------
resource "aws_eks_addon" "fsx_csi_driver" {
  count                    = var.eks.addons.fsx_csi_driver.enabled && var.eks.compute.create_node_group ? 1 : 0
  cluster_name             = aws_eks_cluster.eks_cluster.name
  addon_name               = "aws-fsx-csi-driver"
  addon_version            = var.eks.addons.fsx_csi_driver.version
  service_account_role_arn = var.eks.addons.fsx_csi_driver.role_key != null ? module.iam_roles[var.eks.addons.fsx_csi_driver.role_key].iam_role_arn : var.eks.addons.fsx_csi_driver.role_arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  configuration_values = jsonencode({
    controller = {
      nodeSelector = local.system_node_selector
      tolerations  = local.system_tolerations
      topologySpreadConstraints = [
        merge(local.system_topology_spread_base, {
          labelSelector = {
            matchLabels = {
              app = "fsx-csi-controller"
            }
          }
        })
      ]
    }
    node = { tolerations = local.all_workload_node_tolerations }
  })

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.key}-fsx-csi-driver-addon"
  })

  depends_on = [
    module.eks_node_group,
    module.iam_roles,
    aws_eks_addon.coredns,
    aws_eks_addon.pod_identity_agent
  ]
}

resource "aws_eks_addon" "privateca_issuer" {
  count                       = var.eks.addons.privateca_issuer.enabled && var.eks.compute.create_node_group ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "aws-privateca-issuer"
  addon_version               = var.eks.addons.privateca_issuer.version
  resolve_conflicts_on_update = "PRESERVE"
  configuration_values        = jsonencode({ nodeSelector = local.system_node_selector, tolerations = local.system_tolerations })
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.key}-privateca-issuer-addon"
  })

  depends_on = [
    module.eks_node_group,
    aws_eks_addon.coredns,
    aws_eks_addon.pod_identity_agent
  ]
}

resource "helm_release" "secrets_store_aws_provider" {
  count      = var.eks.addons.secrets_manager_csi_driver.enabled && var.eks.compute.create_node_group ? 1 : 0
  name       = "secrets-provider-aws"
  namespace  = "kube-system"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  version    = var.eks.addons.secrets_manager_csi_driver.aws_provider_version

  cleanup_on_fail = true
  replace         = true
  force_update    = true

  values = [
    yamlencode(merge({
      secrets-store-csi-driver = {
        syncSecret = {
          enabled = true
        }
        enableSecretRotation = var.eks.addons.secrets_manager_csi_driver.enable_secret_rotation
        rotationPollInterval = var.eks.addons.secrets_manager_csi_driver.rotation_poll_interval
      }
      }, { tolerations = local.all_workload_node_tolerations }
    ))
  ]

  depends_on = [
    module.eks_node_group,
    aws_eks_addon.coredns,
    aws_eks_addon.pod_identity_agent
  ]
}

#--------------------------------------------------------------------
# AWS Load Balancer Controller (Helm) - Tier 3
#--------------------------------------------------------------------
resource "helm_release" "aws_load_balancer_controller" {
  count      = var.eks.ingress.aws_load_balancer_controller.enabled && var.eks.compute.create_node_group ? 1 : 0
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.eks.ingress.aws_load_balancer_controller.version

  cleanup_on_fail = true
  replace         = true
  force_update    = true

  values = [
    yamlencode(merge({
      clusterName = aws_eks_cluster.eks_cluster.name
      region      = data.aws_region.current.name
      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
        annotations = {
          "eks.amazonaws.com/role-arn" = var.eks.ingress.aws_load_balancer_controller.role_key != null ? module.iam_roles[var.eks.ingress.aws_load_balancer_controller.role_key].iam_role_arn : var.eks.ingress.aws_load_balancer_controller.role_arn
        }
      }
      topologySpreadConstraints = [
        merge(local.system_topology_spread_base, {
          labelSelector = {
            matchLabels = {
              "app.kubernetes.io/name"     = "aws-load-balancer-controller"
              "app.kubernetes.io/instance" = "aws-load-balancer-controller"
            }
          }
        })
      ]
    }, { nodeSelector = local.system_node_selector, tolerations = local.system_tolerations }))
  ]

  depends_on = [
    module.eks_node_group,
    module.iam_roles,
    aws_eks_addon.coredns,
    aws_eks_addon.pod_identity_agent
  ]
}

#--------------------------------------------------------------------
# NGINX Ingress Controller (Helm) - Tier 3
#--------------------------------------------------------------------
resource "helm_release" "nginx_ingress" {
  for_each   = local.nginx_ingress_enabled ? local.nginx_ingress_map : {}
  name       = each.value.release_name
  namespace  = each.value.namespace
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = each.value.version
  timeout    = each.value.timeout

  cleanup_on_fail  = true
  replace          = true
  force_update     = true
  create_namespace = true

  values = concat([
    yamlencode({
      controller = {
        replicaCount = each.value.replica_count
        ingressClass = each.value.ingress_class_name
        extraArgs = contains(keys(local.nginx_ingress_tls_secret_map), each.key) ? {
          default-ssl-certificate = "${local.nginx_ingress_tls_secret_map[each.key].namespace}/${local.nginx_ingress_tls_secret_map[each.key].name}"
        } : {}
        ingressClassResource = {
          name            = each.value.ingress_class_name
          enabled         = true
          default         = false
          controllerValue = "k8s.io/${each.value.ingress_class_name}-ingress-nginx"
        }
        nodeSelector = local.system_node_selector
        tolerations  = local.system_tolerations
        # The admission certgen Jobs are Helm hooks and do not inherit controller.* values.
        admissionWebhooks = {
          patch = {
            nodeSelector = local.system_node_selector
            tolerations  = local.system_tolerations
          }
        }
        topologySpreadConstraints = [
          merge(local.system_topology_spread_base, {
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name"      = "ingress-nginx"
                "app.kubernetes.io/instance"  = each.value.release_name
                "app.kubernetes.io/component" = "controller"
              }
            }
          })
        ]
        service = {
          type                  = "LoadBalancer"
          externalTrafficPolicy = "Local"
          annotations           = local.nginx_ingress_service_annotations[each.key]
        }
      }
    })
  ], [for value in each.value.values : yamlencode(value)])

  depends_on = [
    module.eks_node_group,
    aws_eks_addon.coredns,
    aws_eks_addon.pod_identity_agent,
    helm_release.aws_load_balancer_controller
  ]
}

resource "kubernetes_secret_v1" "nginx_ingress_tls_secret" {
  for_each = local.nginx_ingress_tls_secret_map

  metadata {
    name      = each.value.name
    namespace = each.value.namespace
  }

  data = {
    "tls.crt" = each.value.certificate
    "tls.key" = each.value.private_key
  }

  type = "kubernetes.io/tls"

  depends_on = [
    aws_eks_cluster.eks_cluster,
    helm_release.nginx_ingress
  ]
}

#--------------------------------------------------------------------
# NGINX Gateway Fabric (Helm) - Tier 3
#--------------------------------------------------------------------
resource "helm_release" "gateway_api" {
  count      = local.gateway_api_enabled ? 1 : 0
  name       = local.gateway_api_config.release_name
  namespace  = local.gateway_api_config.namespace
  repository = "oci://ghcr.io/nginx/charts"
  chart      = "nginx-gateway-fabric"
  version    = local.gateway_api_config.version

  cleanup_on_fail  = true
  replace          = true
  force_update     = true
  create_namespace = true

  values = concat([
    yamlencode({
      nginxGateway = {
        gatewayClassName      = local.gateway_api_config.gateway_class_name
        gatewayControllerName = local.gateway_api_config.controller_name
        replicas              = local.gateway_api_config.fabric_replicas
        nodeSelector          = local.system_node_selector
        tolerations           = local.system_tolerations
        topologySpreadConstraints = [
          merge(local.system_topology_spread_base, {
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name"     = "nginx-gateway-fabric"
                "app.kubernetes.io/instance" = local.gateway_api_config.release_name
              }
            }
          })
        ]
      }
      nginx = {
        replicas = local.gateway_api_config.nginx_replicas
        pod = {
          nodeSelector = local.system_node_selector
          tolerations  = local.system_tolerations
          topologySpreadConstraints = [
            merge(local.system_topology_spread_base, {
              labelSelector = {
                matchLabels = {
                  "app.kubernetes.io/managed-by" = "nginx-gateway-fabric"
                }
              }
            })
          ]
        }
        service = {
          type                  = "LoadBalancer"
          externalTrafficPolicy = "Local"
          annotations           = local.gateway_api_service_annotations
        }
      }
    })
  ], [for value in local.gateway_api_config.values : yamlencode(value)])

  depends_on = [
    module.eks_node_group,
    aws_eks_addon.coredns,
    aws_eks_addon.pod_identity_agent,
    helm_release.aws_load_balancer_controller
  ]
}

#--------------------------------------------------------------------
# Cluster Autoscaler (Helm) - Tier 3
#--------------------------------------------------------------------
resource "helm_release" "cluster_autoscaler" {
  count      = var.eks.compute.cluster_autoscaler.enabled && var.eks.compute.create_node_group ? 1 : 0
  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.eks.compute.cluster_autoscaler.version

  cleanup_on_fail = true
  replace         = true
  force_update    = true

  values = [
    yamlencode(merge({
      autoDiscovery = {
        clusterName = aws_eks_cluster.eks_cluster.name
      }
      awsRegion = data.aws_region.current.name
      rbac = {
        serviceAccount = {
          create = true
          name   = "cluster-autoscaler"
          annotations = {
            "eks.amazonaws.com/role-arn" = var.eks.compute.cluster_autoscaler.role_key != null ? module.iam_roles[var.eks.compute.cluster_autoscaler.role_key].iam_role_arn : var.eks.compute.cluster_autoscaler.role_arn
          }
        }
      }
      extraArgs = {
        balance-similar-node-groups = true
        skip-nodes-with-system-pods = false
        expander                    = "least-waste"
      }
    }, { nodeSelector = local.system_node_selector, tolerations = local.system_tolerations }))
  ]

  depends_on = [
    module.eks_node_group,
    module.iam_roles,
    aws_eks_addon.coredns,
    aws_eks_addon.pod_identity_agent
  ]
}

#--------------------------------------------------------------------
# Karpenter - SQS Interruption Queue
#--------------------------------------------------------------------
resource "aws_sqs_queue" "karpenter_interruption" {
  count                     = local.karpenter_enabled ? 1 : 0
  name                      = local.karpenter_interruption_queue_name
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true

  tags = merge(var.common.tags, {
    "Name" = local.karpenter_interruption_queue_name
  })
}

resource "aws_sqs_queue_policy" "karpenter_interruption" {
  count     = local.karpenter_enabled ? 1 : 0
  queue_url = aws_sqs_queue.karpenter_interruption[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "KarpenterInterruptionQueuePolicy"
    Statement = [
      {
        Sid    = "SqsWrite"
        Effect = "Allow"
        Principal = {
          Service = ["events.amazonaws.com", "sqs.amazonaws.com"]
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_interruption[0].arn
      }
    ]
  })
}

#--------------------------------------------------------------------
# Karpenter - EventBridge Rules for Interruption Handling
#--------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "karpenter_interruption" {
  for_each    = local.karpenter_enabled ? local.karpenter_interruption_events : {}
  name        = "${local.karpenter_interruption_queue_name}-${replace(each.key, "_", "-")}"
  description = "Karpenter interruption handling - ${each.key}"

  event_pattern = jsonencode({
    source      = each.value.source
    detail-type = each.value.detail-type
  })

  tags = var.common.tags
}

resource "aws_cloudwatch_event_target" "karpenter_interruption" {
  for_each  = local.karpenter_enabled ? local.karpenter_interruption_events : {}
  rule      = aws_cloudwatch_event_rule.karpenter_interruption[each.key].name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.karpenter_interruption[0].arn
}

#--------------------------------------------------------------------
# Karpenter - Node Access Entry
#--------------------------------------------------------------------
resource "aws_eks_access_entry" "karpenter_node" {
  count         = local.create_karpenter_node_access_entry ? 1 : 0
  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = local.karpenter_node_role_arn
  type          = "EC2_LINUX"
}

#--------------------------------------------------------------------
# Karpenter (Helm) - Controller
#--------------------------------------------------------------------
resource "helm_release" "karpenter" {
  count      = local.karpenter_enabled ? 1 : 0
  name       = "karpenter"
  namespace  = local.karpenter.namespace
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = local.karpenter.chart_version

  cleanup_on_fail = true
  replace         = true
  force_update    = true

  values = [
    yamlencode(merge({
      settings = {
        clusterName       = aws_eks_cluster.eks_cluster.name
        clusterEndpoint   = aws_eks_cluster.eks_cluster.endpoint
        interruptionQueue = aws_sqs_queue.karpenter_interruption[0].name
      }
      serviceAccount = {
        create = true
        name   = "karpenter"
        annotations = {
          "eks.amazonaws.com/role-arn" = local.karpenter_controller_role_arn
        }
      }
    }, { nodeSelector = local.system_node_selector, tolerations = local.system_tolerations }))
  ]

  depends_on = [
    module.eks_node_group,
    module.iam_roles,
    aws_eks_addon.coredns,
    aws_eks_addon.pod_identity_agent,
    aws_eks_access_entry.karpenter_node,
    aws_sqs_queue_policy.karpenter_interruption,
    aws_cloudwatch_event_target.karpenter_interruption
  ]
}

#--------------------------------------------------------------------
# Karpenter - NodeClass and NodePool manifests
#--------------------------------------------------------------------
resource "kubectl_manifest" "karpenter_objects" {
  for_each = {
    for document in local.karpenter_manifest_documents :
    "${yamldecode(document).kind}/${yamldecode(document).metadata.name}" => document
  }

  yaml_body = each.value

  depends_on = [
    helm_release.karpenter
  ]
}

#--------------------------------------------------------------------
# External DNS (Helm) - Tier 3
#--------------------------------------------------------------------
resource "helm_release" "external_dns" {
  count      = var.eks.ingress.external_dns.enabled && var.eks.compute.create_node_group ? 1 : 0
  name       = "external-dns"
  namespace  = var.eks.ingress.external_dns.namespace != null ? var.eks.ingress.external_dns.namespace : "kube-system"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = var.eks.ingress.external_dns.version

  cleanup_on_fail = true
  replace         = true
  force_update    = true

  values = [
    yamlencode(merge({
      provider = "aws"
      serviceAccount = {
        create = true
        name   = "external-dns"
        annotations = {
          "eks.amazonaws.com/role-arn" = var.eks.ingress.external_dns.role_key != null ? module.iam_roles[var.eks.ingress.external_dns.role_key].iam_role_arn : var.eks.ingress.external_dns.role_arn
        }
      }
      policy        = var.eks.ingress.external_dns.policy != null ? var.eks.ingress.external_dns.policy : "upsert-only"
      txtOwnerId    = aws_eks_cluster.eks_cluster.name
      domainFilters = var.eks.ingress.external_dns.domain_filters != null ? var.eks.ingress.external_dns.domain_filters : []
      sources       = var.eks.ingress.external_dns.sources != null ? var.eks.ingress.external_dns.sources : ["service", "ingress"]
      logLevel      = var.eks.ingress.external_dns.log_level != null ? var.eks.ingress.external_dns.log_level : "info"
    }, { nodeSelector = local.system_node_selector, tolerations = local.system_tolerations }))
  ]

  depends_on = [
    module.eks_node_group,
    module.iam_roles,
    aws_eks_addon.coredns,
    aws_eks_addon.pod_identity_agent
  ]
}

#--------------------------------------------------------------------
# EKS Addons - Tier 4: Observability (Install Last)
#--------------------------------------------------------------------
resource "aws_eks_addon" "metrics_server" {
  count                       = var.eks.addons.metrics_server.enabled && var.eks.compute.create_node_group ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "metrics-server"
  addon_version               = var.eks.addons.metrics_server.version
  resolve_conflicts_on_update = "PRESERVE"
  configuration_values        = jsonencode({ nodeSelector = local.system_node_selector, tolerations = local.system_tolerations })

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.key}-metrics-server-addon"
  })

  depends_on = [
    module.eks_node_group,
    aws_eks_addon.coredns,
    aws_eks_addon.ebs_csi_driver,
    helm_release.aws_load_balancer_controller
  ]
}

resource "aws_eks_addon" "cloudwatch_observability" {
  count = var.eks.addons.cloudwatch_observability.enabled && var.eks.compute.create_node_group && (var.eks.addons.cloudwatch_observability.role_arn != null ||
  var.eks.addons.cloudwatch_observability.role_key != null) ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "amazon-cloudwatch-observability"
  addon_version               = var.eks.addons.cloudwatch_observability.version
  resolve_conflicts_on_update = "PRESERVE"
  service_account_role_arn    = var.eks.addons.cloudwatch_observability.role_key != null ? module.iam_roles[var.eks.addons.cloudwatch_observability.role_key].iam_role_arn : var.eks.addons.cloudwatch_observability.role_arn
  configuration_values = jsonencode({
    tolerations = local.all_workload_node_tolerations
    manager = {
      tolerations = local.all_workload_node_tolerations
    }
  })

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.key}-cloudwatch-observability-addon"
  })

  depends_on = [
    module.eks_node_group,
    aws_eks_addon.coredns,
    aws_eks_addon.pod_identity_agent,
    aws_eks_addon.ebs_csi_driver,
    helm_release.secrets_store_aws_provider,
    helm_release.aws_load_balancer_controller
  ]
}

#--------------------------------------------------------------------
# Fluent Bit (Helm) - Tier 4: Observability
#--------------------------------------------------------------------
resource "helm_release" "fluent_bit" {
  count      = var.eks.addons.fluent_bit.enabled && var.eks.compute.create_node_group ? 1 : 0
  name       = "fluent-bit"
  namespace  = var.eks.addons.fluent_bit.namespace != null ? var.eks.addons.fluent_bit.namespace : "amazon-cloudwatch"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = var.eks.addons.fluent_bit.version

  create_namespace = true
  cleanup_on_fail  = true
  replace          = true
  force_update     = true

  values = [
    yamlencode(merge({
      serviceAccount = {
        create = true
        name   = "fluent-bit"
        annotations = {
          "eks.amazonaws.com/role-arn" = var.eks.addons.fluent_bit.role_key != null ? module.iam_roles[var.eks.addons.fluent_bit.role_key].iam_role_arn : var.eks.addons.fluent_bit.role_arn
        }
      }
      config = var.eks.addons.fluent_bit.firehose_delivery_stream != null ? {
        outputs = join("\n", [
          "[OUTPUT]",
          "    Name              kinesis_firehose",
          "    Match             *",
          "    region            ${data.aws_region.current.name}",
          "    delivery_stream   ${var.eks.addons.fluent_bit.firehose_delivery_stream}",
        ])
      } : null
    }, { tolerations = local.all_workload_node_tolerations }))
  ]

  depends_on = [
    module.eks_node_group,
    module.iam_roles,
    aws_eks_addon.coredns,
    aws_eks_addon.pod_identity_agent
  ]
}

#--------------------------------------------------------------------
# Grafana + Prometheus (Helm) - Tier 4: Observability
#--------------------------------------------------------------------
resource "helm_release" "kube_prometheus_stack" {
  count           = var.eks.addons.kube_prometheus_stack.enabled && var.eks.compute.create_node_group ? 1 : 0
  name            = "kube-prometheus-stack"
  namespace       = var.eks.addons.kube_prometheus_stack.grafana_namespace != null ? var.eks.addons.kube_prometheus_stack.grafana_namespace : "monitoring"
  repository      = "https://prometheus-community.github.io/helm-charts"
  chart           = "kube-prometheus-stack"
  version         = var.eks.addons.kube_prometheus_stack.version
  timeout         = var.eks.addons.kube_prometheus_stack.timeout != null ? var.eks.addons.kube_prometheus_stack.timeout : 900
  wait            = true
  atomic          = true
  upgrade_install = var.eks.addons.kube_prometheus_stack.upgrade_install

  max_history      = 5
  create_namespace = true
  cleanup_on_fail  = true
  replace          = true
  force_update     = true

  values = [
    yamlencode({
      grafana = merge({
        enabled = true
        service = {
          type = var.eks.addons.kube_prometheus_stack.grafana_service_type != null ? var.eks.addons.kube_prometheus_stack.grafana_service_type : "ClusterIP"
        }
        ingress = {
          enabled          = var.eks.addons.kube_prometheus_stack.grafana_ingress_enabled
          ingressClassName = var.eks.addons.kube_prometheus_stack.grafana_ingress_class_name
          annotations      = var.eks.addons.kube_prometheus_stack.grafana_ingress_annotations
          hosts = [
            for host in var.eks.addons.kube_prometheus_stack.grafana_ingress_hosts : {
              host = host
              paths = [
                {
                  path     = "/"
                  pathType = "Prefix"
                }
              ]
            }
          ]
        }
        persistence = {
          enabled          = var.eks.addons.kube_prometheus_stack.grafana_persistence_enabled
          size             = var.eks.addons.kube_prometheus_stack.grafana_persistence_size != null ? var.eks.addons.kube_prometheus_stack.grafana_persistence_size : "10Gi"
          storageClassName = var.eks.addons.kube_prometheus_stack.grafana_persistence_storage_class
        }
        }, { nodeSelector = local.system_node_selector, tolerations = local.system_tolerations }
      )
      prometheus = {
        prometheusSpec = merge(
          {
            retention = var.eks.addons.kube_prometheus_stack.prometheus_retention != null ? var.eks.addons.kube_prometheus_stack.prometheus_retention : "15d"
          },
          var.eks.addons.kube_prometheus_stack.prometheus_persistence_enabled ? {
            storageSpec = {
              volumeClaimTemplate = {
                spec = {
                  accessModes = ["ReadWriteOnce"]
                  resources = {
                    requests = {
                      storage = var.eks.addons.kube_prometheus_stack.prometheus_persistence_size != null ? var.eks.addons.kube_prometheus_stack.prometheus_persistence_size : "20Gi"
                    }
                  }
                  storageClassName = var.eks.addons.kube_prometheus_stack.prometheus_persistence_storage_class
                }
              }
            }
          } : { storageSpec = null },
          { nodeSelector = local.system_node_selector, tolerations = local.system_tolerations }
        )
      }
      prometheusOperator = {
        nodeSelector = local.system_node_selector
        tolerations  = local.system_tolerations
        admissionWebhooks = {
          deployment = {
            nodeSelector = local.system_node_selector
            tolerations  = local.system_tolerations
          }
          patch = {
            nodeSelector = local.system_node_selector
            tolerations  = local.system_tolerations
          }
        }
      }
      "kube-state-metrics" = {
        nodeSelector = local.system_node_selector
        tolerations  = local.system_tolerations
      }
      alertmanager = {
        alertmanagerSpec = {
          nodeSelector = local.system_node_selector
          tolerations  = local.system_tolerations
        }
      }
      "prometheus-node-exporter" = {
        tolerations = local.all_workload_node_tolerations
      }
    })
  ]

  depends_on = [
    module.eks_node_group,
    aws_eks_addon.coredns,
    aws_eks_addon.pod_identity_agent,
    aws_eks_addon.metrics_server,
    aws_eks_addon.ebs_csi_driver,
    kubernetes_storage_class_v1.gp3,
    helm_release.aws_load_balancer_controller
  ]
}

#--------------------------------------------------------------------
# Kubecost (Helm) - Tier 4: Observability
#--------------------------------------------------------------------
resource "helm_release" "kubecost" {
  count            = var.eks.addons.kubecost.enabled && var.eks.compute.create_node_group ? 1 : 0
  name             = "kubecost"
  namespace        = var.eks.addons.kubecost.namespace
  repository       = "https://kubecost.github.io/cost-analyzer/"
  chart            = "cost-analyzer"
  version          = var.eks.addons.kubecost.version
  timeout          = var.eks.addons.kubecost.timeout
  wait             = true
  atomic           = true
  max_history      = 5
  create_namespace = true
  cleanup_on_fail  = true

  values = concat([
    yamlencode(merge(
      {},
      coalesce(var.eks.addons.kubecost.storage_class, var.eks.addons.kube_prometheus_stack.prometheus_persistence_storage_class) != null ? {
        persistentVolume = {
          storageClass = coalesce(var.eks.addons.kubecost.storage_class, var.eks.addons.kube_prometheus_stack.prometheus_persistence_storage_class)
        }
      } : {}
    )),
    yamlencode(merge(
      {
        serviceAccount = {
          create = true
          name   = "kubecost"
          annotations = {
            "eks.amazonaws.com/role-arn" = var.eks.addons.kubecost.role_key != null ? module.iam_roles[var.eks.addons.kubecost.role_key].iam_role_arn : var.eks.addons.kubecost.role_arn
          }
        }
        # Pod-level scheduling for the cost-analyzer Deployment. The kubecostFrontend
        # and kubecostModel keys below are container-scoped and do not affect it.
        nodeSelector = local.system_node_selector
        tolerations  = local.system_tolerations
        forecasting = {
          nodeSelector = local.system_node_selector
          tolerations  = local.system_tolerations
        }
        grafana = {
          nodeSelector = local.system_node_selector
          tolerations  = local.system_tolerations
        }
        global = {
          clusterId = aws_eks_cluster.eks_cluster.name
        }
        ingress = {
          enabled     = var.eks.addons.kubecost.ingress_enabled
          className   = var.eks.addons.kubecost.ingress_class_name
          pathType    = "Prefix"
          annotations = var.eks.addons.kubecost.ingress_annotations
          hosts       = var.eks.addons.kubecost.ingress_hosts
        }
        kubecostFrontend = {
          nodeSelector = local.system_node_selector
          tolerations  = local.system_tolerations
        }
        kubecostModel = {
          nodeSelector = local.system_node_selector
          tolerations  = local.system_tolerations
        }
        prometheus = {
          server = merge(
            {
              nodeSelector = local.system_node_selector
              tolerations  = local.system_tolerations
              global = {
                external_labels = {
                  cluster_id = aws_eks_cluster.eks_cluster.name
                }
              }
            },
            var.eks.addons.kube_prometheus_stack.prometheus_persistence_storage_class != null ? {
              persistentVolume = {
                storageClass = var.eks.addons.kube_prometheus_stack.prometheus_persistence_storage_class
              }
            } : {}
          )
        }
      },
      {}
    ))
  ], var.eks.addons.kubecost.values)

  depends_on = [
    module.eks_node_group,
    aws_eks_addon.coredns,
    aws_eks_addon.metrics_server,
    aws_eks_addon.ebs_csi_driver,
    kubernetes_storage_class_v1.gp3
  ]
}

#--------------------------------------------------------------------
# Key Pair Resource for EKS EC2 Node Group
#--------------------------------------------------------------------

resource "tls_private_key" "key" {
  count     = var.eks.compute.create_node_group ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  count      = var.eks.compute.create_node_group ? 1 : 0
  key_name   = var.eks.compute.key_pair.name
  public_key = tls_private_key.key[0].public_key_openssh
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.compute.key_pair.name}"
    }
  )
}

#--------------------------------------------------------------------
# Secrets Manager Secret for EKS EC2 Node Group Key Pair
#--------------------------------------------------------------------

resource "aws_secretsmanager_secret" "private_key_secret" {
  count                          = var.eks.compute.create_node_group ? 1 : 0
  name_prefix                    = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.compute.key_pair.secret_name}"
  description                    = var.eks.compute.key_pair.secret_description
  recovery_window_in_days        = 7
  force_overwrite_replica_secret = true
  policy                         = var.eks.compute.key_pair.policy
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.compute.key_pair.secret_name}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "private_key_secret_version" {
  count         = var.eks.compute.create_node_group ? 1 : 0
  secret_id     = aws_secretsmanager_secret.private_key_secret[0].id
  secret_string = tls_private_key.key[0].private_key_pem
}

#--------------------------------------------------------------------
# Security Group for EKS Cluster
#--------------------------------------------------------------------
module "security_group" {
  for_each       = var.eks.security_groups != null ? { for item in var.eks.security_groups : item.key => item } : {}
  source         = "../Security-group"
  common         = var.common
  security_group = each.value
}

#--------------------------------------------------------------------
# Security Group Rules for EKS Cluster
#--------------------------------------------------------------------
module "security_group_rules" {
  source   = "../Security-group-rules"
  for_each = var.eks.security_group_rules != null ? { for item in var.eks.security_group_rules : item.sg_key => item } : {}
  common   = var.common
  security_group = {
    security_group_id = each.value.sg_key != null ? module.security_group[each.value.sg_key].security_group_id : each.value.security_group_id
    egress_rules = each.value.egress_rules != null ? [
      for rule in each.value.egress_rules : merge(rule, {
        target_sg_id = rule.target_sg_key == "eks_cluster_sg_id" ? aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id : (
          rule.target_sg_key != null ? module.security_group[rule.target_sg_key].security_group_id : (
            rule.target_sg_id == "eks_cluster_sg_id" ? aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id : rule.target_sg_id
          )
        )
      })
    ] : null
    ingress_rules = each.value.ingress_rules != null ? [
      for rule in each.value.ingress_rules : merge(rule, {
        source_sg_id = rule.source_sg_key == "eks_cluster_sg_id" ? aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id : (
          rule.source_sg_key != null ? module.security_group[rule.source_sg_key].security_group_id : (
            rule.source_sg_id == "eks_cluster_sg_id" ? aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id : rule.source_sg_id
          )
        )
      })
    ] : null
  }
  depends_on = [module.security_group]
}

#--------------------------------------------------------------------
# Launch template for EKS Node Group
#--------------------------------------------------------------------
module "launch_template" {
  for_each = var.eks.compute.create_node_group && var.eks.compute.launch_templates != null ? { for item in var.eks.compute.launch_templates : item.key => item } : {}
  source   = "../Launch_template"
  common   = var.common
  launch_template = merge(
    each.value,
    each.value,
    {
      vpc_security_group_ids = concat(
        each.value.vpc_security_group_keys != null ? [
          for sg_key in each.value.vpc_security_group_keys :
          sg_key == "eks_cluster_sg_id" ? aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id : module.security_group[sg_key].security_group_id
        ] : [],
        each.value.vpc_security_group_ids != null ? each.value.vpc_security_group_ids : []
      )
    },
    {
      key_name = each.value.ec2_ssh_key != null ? each.value.ec2_ssh_key : aws_key_pair.generated_key[0].key_name
    },
    {
      user_data = each.value.user_data == null ? base64encode(yamlencode({
        apiVersion = "node.eks.aws/v1alpha1"
        kind       = "NodeConfig"
        spec = {
          cluster = {
            name                 = aws_eks_cluster.eks_cluster.id
            apiServerEndpoint    = aws_eks_cluster.eks_cluster.endpoint
            certificateAuthority = aws_eks_cluster.eks_cluster.certificate_authority[0].data
            cidr                 = aws_eks_cluster.eks_cluster.kubernetes_network_config[0].service_ipv4_cidr
          }
        }
      })) : each.value.user_data
    }
  )
  depends_on = [aws_eks_cluster.eks_cluster]
}


#--------------------------------------------------------------------
# EKS Node Group
#--------------------------------------------------------------------
module "eks_node_group" {
  for_each = var.eks.compute.create_node_group && var.eks.compute.eks_node_groups != null ? { for item in var.eks.compute.eks_node_groups : item.key => item } : {}
  source   = "../EKS-Node-group"
  common   = var.common
  eks_node_group = merge(
    each.value,
    {
      cluster_name = each.value.cluster_key != null ? each.value.cluster_key : aws_eks_cluster.eks_cluster.name
    },
    {
      launch_template = each.value.launch_template_key != null ? {
        id      = module.launch_template[each.value.launch_template_key].id
        version = try(each.value.launch_template.version, "$Latest")
      } : each.value.launch_template
    }
  )
  depends_on = [aws_eks_cluster.eks_cluster, module.launch_template]
}


#--------------------------------------------------------------------
# EKS Service account
#--------------------------------------------------------------------
module "service_account" {
  for_each = var.eks.create_service_accounts && var.eks.service_accounts != null ? { for item in var.eks.service_accounts : item.key => item } : {}
  source   = "../EKS-Service-account"
  common   = var.common
  eks_service_account = merge(
    each.value,
    {
      role_arn = each.value.role_key != null ? module.iam_roles[each.value.role_key].iam_role_arn : each.value.role_arn
    }
  )
  depends_on = [aws_eks_cluster.eks_cluster, kubernetes_namespace_v1.namespace]
}

#--------------------------------------------------------------------
# EKS Cluster IAM Roles for Service Accounts
#--------------------------------------------------------------------
module "iam_roles" {
  for_each = var.eks.create_service_accounts && var.eks.iam_roles != null ? { for item in var.eks.iam_roles : item.key => item } : {}
  source   = "./IAM-Roles"
  common   = var.common
  iam_role = merge(
    each.value,
    {
      policy = each.value.policy != null ? merge(
        each.value.policy,
        {
          cluster_name = aws_eks_cluster.eks_cluster.name
        }
      ) : null
      assume_role_policy = each.value.assume_role_policy != null ? jsonencode(jsondecode(file(each.value.assume_role_policy))) : jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid    = "EKSServiceAccountAssumeRoleWithWebIdentity"
            Effect = "Allow"
            Principal = {
              Federated = aws_iam_openid_connect_provider.eks_oidc.arn
            }
            Action = "sts:AssumeRoleWithWebIdentity"
            Condition = {
              StringEquals = {
                "${aws_iam_openid_connect_provider.eks_oidc.url}:sub" = "system:serviceaccount:${each.value.service_account_namespace}:${each.value.service_account_name}"
                "${aws_iam_openid_connect_provider.eks_oidc.url}:aud" = "sts.amazonaws.com"
              }
            }
          }
        ]
      })
    }
  )
  depends_on = [aws_eks_cluster.eks_cluster]
}

resource "aws_eks_pod_identity_association" "pia" {
  for_each     = var.eks.enable_eks_pia && var.eks.eks_pia != null ? { for item in var.eks.eks_pia : item.key => item } : {}
  cluster_name = aws_eks_cluster.eks_cluster.name
  namespace    = each.value.service_account_namespace
  service_account = (each.value.service_account_keys != null && length(each.value.service_account_keys) > 0 && contains(local.created_service_account_keys, each.key) ? module.service_account[each.key].service_account_name : each.value.service_account_name
  )
  role_arn   = each.value.role_key != null ? module.iam_roles[each.value.role_key].iam_role_arn : each.value.role_arn
  depends_on = [aws_eks_cluster.eks_cluster, kubernetes_namespace_v1.namespace, module.service_account]
}

#--------------------------------------------------------------------
# Kubernetes RBAC - Cluster Roles
#--------------------------------------------------------------------
resource "kubernetes_cluster_role_v1" "cluster_role" {
  for_each = try({ for role in var.eks.auth.cluster_roles : role.key => role }, {}
  )

  metadata {
    name   = each.value.name
    labels = each.value.labels
  }

  dynamic "rule" {
    for_each = each.value.rules
    content {
      api_groups = rule.value.api_groups
      resources  = rule.value.resources
      verbs      = rule.value.verbs
    }
  }

  depends_on = [aws_eks_cluster.eks_cluster]
}

#--------------------------------------------------------------------
# Kubernetes RBAC - Cluster Role Bindings
#--------------------------------------------------------------------
resource "kubernetes_cluster_role_binding_v1" "cluster_role_binding" {
  for_each = try({ for binding in var.eks.auth.cluster_role_bindings : binding.key => binding }, {}
  )

  metadata {
    name   = each.value.name
    labels = each.value.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = each.value.cluster_role_key != null ? kubernetes_cluster_role_v1.cluster_role[each.value.cluster_role_key].metadata[0].name : each.value.cluster_role_name
  }

  dynamic "subject" {
    for_each = each.value.subjects
    content {
      kind      = subject.value.kind
      name      = subject.value.name
      namespace = subject.value.namespace
      api_group = subject.value.api_group
    }
  }

  depends_on = [aws_eks_cluster.eks_cluster, kubernetes_cluster_role_v1.cluster_role]
}

#--------------------------------------------------------------------
# Kubernetes RBAC - Roles
#--------------------------------------------------------------------
resource "kubernetes_role_v1" "role" {
  for_each = var.eks.auth != null ? try({
    for role in var.eks.auth.roles : role.key => role
    if coalesce(role.namespace, "default") == "default"
    || !contains(
      [for ns in coalesce(var.eks.namespaces, []) : ns.name],
      coalesce(role.namespace, "default")
    )
    || contains(keys(kubernetes_namespace_v1.namespace), coalesce(role.namespace, "default"))
  }, {}) : {}

  metadata {
    name = each.value.name
    namespace = (
      contains(keys(kubernetes_namespace_v1.namespace), coalesce(each.value.namespace, "default"))
      ? kubernetes_namespace_v1.namespace[coalesce(each.value.namespace, "default")].metadata[0].name
      : coalesce(each.value.namespace, "default")
    )
    labels = each.value.labels
  }

  dynamic "rule" {
    for_each = each.value.rules
    content {
      api_groups = rule.value.api_groups
      resources  = rule.value.resources
      verbs      = rule.value.verbs
    }
  }

  depends_on = [aws_eks_cluster.eks_cluster, kubernetes_namespace_v1.namespace]
}

#--------------------------------------------------------------------
# Kubernetes RBAC - Role Bindings
#--------------------------------------------------------------------
resource "kubernetes_role_binding_v1" "role_binding" {
  for_each = var.eks.auth != null ? try({
    for binding in var.eks.auth.role_bindings : binding.key => binding
    if coalesce(binding.namespace, "default") == "default"
    || !contains(
      [for ns in coalesce(var.eks.namespaces, []) : ns.name],
      coalesce(binding.namespace, "default")
    )
    || contains(keys(kubernetes_namespace_v1.namespace), coalesce(binding.namespace, "default"))
  }, {}) : {}

  metadata {
    name = each.value.name
    namespace = (
      contains(keys(kubernetes_namespace_v1.namespace), coalesce(each.value.namespace, "default"))
      ? kubernetes_namespace_v1.namespace[coalesce(each.value.namespace, "default")].metadata[0].name
      : coalesce(each.value.namespace, "default")
    )
    labels = each.value.labels
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = each.value.role_key != null ? kubernetes_role_v1.role[each.value.role_key].metadata[0].name : each.value.role_name
  }

  dynamic "subject" {
    for_each = each.value.subjects
    content {
      kind = subject.value.kind
      name = subject.value.name
      namespace = (
        subject.value.namespace != null
        ? (
          contains(keys(kubernetes_namespace_v1.namespace), subject.value.namespace)
          ? kubernetes_namespace_v1.namespace[subject.value.namespace].metadata[0].name
          : subject.value.namespace
        )
        : null
      )
      api_group = subject.value.api_group
    }
  }

  depends_on = [aws_eks_cluster.eks_cluster, kubernetes_role_v1.role, kubernetes_namespace_v1.namespace]
}

#--------------------------------------------------------------------
# Kubernetes Namespace (Optional)
#--------------------------------------------------------------------
resource "kubernetes_namespace_v1" "namespace" {
  for_each = var.eks.namespaces != null ? {
    for ns in var.eks.namespaces : ns.name => ns if ns.name != ""
  } : {}

  metadata {
    name   = each.value.name
    labels = each.value.labels
  }

  depends_on = [aws_eks_cluster.eks_cluster]
}

#--------------------------------------------------------------------
# Kubernetes Resource Quotas (Optional)
#--------------------------------------------------------------------
resource "kubernetes_resource_quota_v1" "resource_quota" {
  for_each = var.eks.namespaces != null ? {
    for ns in var.eks.namespaces : ns.name => ns
    if ns.name != "" && ns.resource_quota != null
  } : {}

  metadata {
    name = coalesce(
      each.value.resource_quota.name,
      try(yamldecode(file(each.value.resource_quota.yaml_file)).metadata.name, null),
      "${each.value.name}-quota"
    )
    namespace = kubernetes_namespace_v1.namespace[each.value.name].metadata[0].name
    labels    = each.value.labels
  }

  spec {
    hard   = each.value.resource_quota.yaml_file != null ? yamldecode(file(each.value.resource_quota.yaml_file)).spec.hard : each.value.resource_quota.hard
    scopes = each.value.resource_quota.yaml_file != null ? try(yamldecode(file(each.value.resource_quota.yaml_file)).spec.scopes, null) : each.value.resource_quota.scopes
  }

  depends_on = [aws_eks_cluster.eks_cluster, kubernetes_namespace_v1.namespace]
}

#--------------------------------------------------------------------
# ArgoCD (Helm) - Tier 5: GitOps - exposed through an ALB
#--------------------------------------------------------------------
resource "helm_release" "argocd" {
  count      = local.argocd_enabled ? 1 : 0
  name       = var.eks.ingress.argocd.release_name
  namespace  = var.eks.ingress.argocd.namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.eks.ingress.argocd.version
  timeout    = var.eks.ingress.argocd.timeout

  wait             = true
  atomic           = true
  max_history      = 5
  create_namespace = true
  cleanup_on_fail  = true

  values = concat([
    yamlencode({
      global = {
        nodeSelector = local.system_node_selector
        tolerations  = local.system_tolerations
      }
      configs = {
        # ArgoCD terminates TLS at the ALB, so UI/gRPC traffic arrives as plain HTTP.
        params = {
          "server.insecure" = var.eks.ingress.argocd.server_insecure
        }
        secret = var.eks.ingress.argocd.admin_password_bcrypt != null ? {
          argocdServerAdminPassword = var.eks.ingress.argocd.admin_password_bcrypt
        } : {}
      }
      "redis-ha" = {
        enabled = var.eks.ingress.argocd.ha_enabled
      }
      controller = {
        replicas = var.eks.ingress.argocd.ha_enabled ? 2 : 1
        topologySpreadConstraints = [
          merge(local.system_topology_spread_base, {
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name" = "argocd-application-controller"
              }
            }
          })
        ]
      }
      repoServer = {
        replicas = var.eks.ingress.argocd.ha_enabled ? 2 : 1
        topologySpreadConstraints = [
          merge(local.system_topology_spread_base, {
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name" = "argocd-repo-server"
              }
            }
          })
        ]
      }
      applicationSet = {
        replicas = var.eks.ingress.argocd.ha_enabled ? 2 : 1
        topologySpreadConstraints = [
          merge(local.system_topology_spread_base, {
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name" = "argocd-applicationset-controller"
              }
            }
          })
        ]
      }
      server = {
        replicas = var.eks.ingress.argocd.server_replicas
        topologySpreadConstraints = [
          merge(local.system_topology_spread_base, {
            labelSelector = {
              matchLabels = {
                "app.kubernetes.io/name" = "argocd-server"
              }
            }
          })
        ]
        service = {
          type = "ClusterIP"
        }
        ingress = {
          enabled          = local.argocd_ingress_enabled
          controller       = "aws"
          ingressClassName = var.eks.ingress.argocd.ingress_class_name
          hostname         = var.eks.ingress.argocd.ingress_host
          path             = "/"
          pathType         = "Prefix"
          annotations      = local.argocd_ingress_annotations
          extraHosts = [
            for host in var.eks.ingress.argocd.ingress_extra_hosts : {
              name = host
              path = "/"
            }
          ]
          aws = {
            serviceType            = "ClusterIP"
            backendProtocolVersion = "GRPC"
          }
        }
      }
    })
  ], var.eks.ingress.argocd.values)

  depends_on = [
    module.eks_node_group,
    aws_eks_addon.coredns,
    aws_eks_addon.pod_identity_agent,
    helm_release.aws_load_balancer_controller
  ]
}

#--------------------------------------------------------------------
# cert-manager (Helm) - Optional in-cluster certificate management
#--------------------------------------------------------------------
resource "helm_release" "cert_manager" {
  count = (
    var.eks.compute.create_node_group
    && var.eks.addons.cert_manager.enabled
  ) ? 1 : 0

  name       = "cert-manager"
  namespace  = var.eks.addons.cert_manager.namespace
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.eks.addons.cert_manager.version
  timeout    = 900

  wait             = true
  atomic           = true
  max_history      = 5
  create_namespace = true
  cleanup_on_fail  = true

  values = [
    yamlencode({
      crds = {
        enabled = var.eks.addons.cert_manager.install_crds
      }
      nodeSelector = local.system_node_selector
      tolerations  = local.system_tolerations
      # webhook, cainjector and the startupapicheck hook Job each need their own
      # scheduling values; the top-level keys only apply to the controller.
      webhook = {
        nodeSelector = local.system_node_selector
        tolerations  = local.system_tolerations
      }
      cainjector = {
        nodeSelector = local.system_node_selector
        tolerations  = local.system_tolerations
      }
      startupapicheck = {
        nodeSelector = local.system_node_selector
        tolerations  = local.system_tolerations
      }
    })
  ]

  depends_on = [
    module.eks_node_group,
    aws_eks_addon.coredns
  ]
}

resource "kubectl_manifest" "cert_manager_cluster_issuer" {
  count = (
    var.eks.compute.create_node_group
    && var.eks.addons.cert_manager.enabled
    && var.eks.addons.cert_manager.create_cluster_issuer
  ) ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = var.eks.addons.cert_manager.cluster_issuer_name
    }
    spec = {
      acme = merge(
        {
          email  = var.eks.addons.cert_manager.cluster_issuer_email
          server = var.eks.addons.cert_manager.cluster_issuer_server
          privateKeySecretRef = {
            name = "${var.eks.addons.cert_manager.cluster_issuer_name}-account-key"
          }
          solvers = [
            {
              dns01 = {
                route53 = merge(
                  {
                    region = coalesce(var.eks.addons.cert_manager.route53_region, data.aws_region.current.name)
                  },
                  var.eks.addons.cert_manager.route53_hosted_zone_id != null ? {
                    hostedZoneID = var.eks.addons.cert_manager.route53_hosted_zone_id
                  } : {},
                  local.cert_manager_route53_role_arn != null ? {
                    role = local.cert_manager_route53_role_arn
                  } : {}
                )
              }
            }
          ]
        },
        {}
      )
    }
  })

  depends_on = [helm_release.cert_manager, module.iam_roles]
}

#--------------------------------------------------------------------
# AWX Operator (Helm) - Optional in-cluster Ansible AWX management
#--------------------------------------------------------------------
resource "helm_release" "awx_operator" {
  count      = var.eks.addons.awx_operator.enabled && var.eks.compute.create_node_group ? 1 : 0
  name       = var.eks.addons.awx_operator.release_name
  namespace  = var.eks.addons.awx_operator.namespace
  repository = "https://ansible-community.github.io/awx-operator-helm/"
  chart      = "awx-operator"
  version    = var.eks.addons.awx_operator.version

  create_namespace = true
  cleanup_on_fail  = true
  replace          = true
  force_update     = true

  values = concat([
    yamlencode({
      serviceAccount = {
        name = var.eks.addons.awx_operator.service_account_name
        annotations = {
          "eks.amazonaws.com/role-arn" = var.eks.addons.awx_operator.role_key != null ? module.iam_roles[var.eks.addons.awx_operator.role_key].iam_role_arn : var.eks.addons.awx_operator.role_arn
        }
      }
      "operator-controller" = {
        spec = {
          template = {
            spec = {
              nodeSelector = local.system_node_selector
              tolerations  = local.system_tolerations
            }
          }
        }
      }
    })
  ], var.eks.addons.awx_operator.values)

  depends_on = [
    module.eks_node_group,
    module.iam_roles,
    aws_eks_addon.coredns,
    aws_eks_addon.pod_identity_agent
  ]
}

#--------------------------------------------------------------------
# AWX Instance - the CR the operator reconciles into the actual AWX
# app (web/task pods, Service, and optionally an Ingress for the UI).
# Without this, the operator alone deploys nothing user-facing.
#--------------------------------------------------------------------
resource "kubectl_manifest" "awx_instance" {
  count = (
    var.eks.addons.awx_operator.enabled
    && var.eks.addons.awx_operator.create_instance
    && var.eks.compute.create_node_group
  ) ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "awx.ansible.com/v1beta1"
    kind       = "AWX"
    metadata = {
      name      = var.eks.addons.awx_operator.instance_name
      namespace = var.eks.addons.awx_operator.namespace
    }
    spec = {
      for k, v in merge(
        {
          service_type         = var.eks.addons.awx_operator.service_type
          service_account_name = var.eks.addons.awx_operator.instance_service_account_name
          # The AWX CRD types this field as a YAML string, not a structured list.
          tolerations = yamlencode(local.system_tolerations)
        },
        var.eks.addons.awx_operator.ingress_enabled ? {
          ingress_type        = "ingress"
          ingress_class_name  = var.eks.addons.awx_operator.ingress_class_name
          hostname            = var.eks.addons.awx_operator.ingress_hostname
          ingress_annotations = var.eks.addons.awx_operator.ingress_annotations
          } : {
          ingress_type        = null
          ingress_class_name  = null
          hostname            = null
          ingress_annotations = null
        },
        var.eks.addons.awx_operator.spec
      ) : k => v if v != null
    }
  })

  depends_on = [helm_release.awx_operator]
}