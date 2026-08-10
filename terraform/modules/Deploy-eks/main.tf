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

  karpenter_enabled = var.eks.eks_addons != null && var.eks.eks_addons.enable_karpenter && var.eks.create_node_group
  karpenter         = local.karpenter_enabled ? var.eks.eks_addons.karpenter : null

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
    for node_group in try(var.eks.eks_node_groups, []) : node_group.node_role_arn
    if try(node_group.node_role_arn, null) != null
  ]

  eks_node_group_role_keys = [
    for node_group in try(var.eks.eks_node_groups, []) : node_group.node_role_key
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

  ingress_enabled = var.eks.eks_addons != null && var.eks.eks_addons.enable_ingress && var.eks.create_node_group
  raw_ingress_config = local.ingress_enabled ? var.eks.eks_addons.ingress : {
    nginx       = []
    gateway_api = {}
  }
  nginx_ingress_input   = try(local.raw_ingress_config.nginx, [])
  gateway_api_input     = try(local.raw_ingress_config.gateway_api, {})
  nginx_ingress_enabled = local.ingress_enabled && length(local.nginx_ingress_input) > 0
  gateway_api_enabled   = local.ingress_enabled && length(keys(local.gateway_api_input)) > 0

  nginx_ingress_defaults = {
    replica_count = 2
    scheme        = "internet-facing"
    target_type   = "ip"
  }

  gateway_api_defaults = {
    version             = "2.6.7"
    release_name        = "ngf"
    namespace           = "nginx-gateway"
    gateway_class_name  = "nginx"
    controller_name     = "gateway.nginx.org/nginx-gateway-controller"
    nginx_replicas      = 2
    fabric_replicas     = 1
    scheme              = "internet-facing"
    target_type         = "ip"
    nlb_name            = null
    subnet_ids          = []
    security_group_keys = []
    security_group_ids  = []
    service_annotations = {}
    values              = []
  }

  ingress_config = local.ingress_enabled ? merge(
    {
      gateway_api = local.gateway_api_defaults
    },
    local.raw_ingress_config,
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
      ingress.nlb_name != null ? {
        "service.beta.kubernetes.io/aws-load-balancer-name" = ingress.nlb_name
      } : {},
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
    local.gateway_api_config.nlb_name != null ? {
      "service.beta.kubernetes.io/aws-load-balancer-name" = local.gateway_api_config.nlb_name
    } : {},
    local.gateway_api_config.service_annotations
  ) : {}
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
  count                       = var.eks.eks_addons != null && var.eks.eks_addons.enable_vpc_cni ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "vpc-cni"
  addon_version               = var.eks.eks_addons.vpc_cni_version
  resolve_conflicts_on_update = "PRESERVE"
  configuration_values = jsonencode({
    for k, v in merge(
      { tolerations = local.all_workload_node_tolerations },
      var.eks.eks_addons.enable_prefix_delegation ? {
        enableNetworkPolicy = "true"
        env = {
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = tostring(var.eks.eks_addons.warm_prefix_target)
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
  count                       = var.eks.eks_addons != null && var.eks.eks_addons.enable_kube_proxy ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "kube-proxy"
  addon_version               = var.eks.eks_addons.kube_proxy_version
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
  count                       = var.eks.eks_addons != null && var.eks.eks_addons.enable_coredns && var.eks.create_node_group ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "coredns"
  addon_version               = var.eks.eks_addons.coredns_version
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
  count                       = var.eks.eks_addons != null && var.eks.eks_addons.enable_pod_identity_agent && var.eks.create_node_group ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = var.eks.eks_addons.pod_identity_agent_version
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
  count                    = var.eks.eks_addons != null && var.eks.eks_addons.enable_ebs_csi_driver && var.eks.create_node_group ? 1 : 0
  cluster_name             = aws_eks_cluster.eks_cluster.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.eks.eks_addons.ebs_csi_driver_version
  service_account_role_arn = var.eks.eks_addons.ebs_csi_driver_role_key != null ? module.iam_roles[var.eks.eks_addons.ebs_csi_driver_role_key].iam_role_arn : var.eks.eks_addons.ebs_csi_driver_role_arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  configuration_values = jsonencode({
    controller = { nodeSelector = local.system_node_selector, tolerations = local.system_tolerations }
    node       = { tolerations = local.all_workload_node_tolerations }
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
  count = var.eks.eks_addons != null && var.eks.eks_addons.enable_ebs_csi_driver && var.eks.create_node_group ? 1 : 0
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
  count                    = var.eks.eks_addons != null && var.eks.eks_addons.enable_efs_csi_driver && var.eks.create_node_group ? 1 : 0
  cluster_name             = aws_eks_cluster.eks_cluster.name
  addon_name               = "aws-efs-csi-driver"
  addon_version            = var.eks.eks_addons.efs_csi_driver_version
  service_account_role_arn = var.eks.eks_addons.efs_csi_driver_role_key != null ? module.iam_roles[var.eks.eks_addons.efs_csi_driver_role_key].iam_role_arn : var.eks.eks_addons.efs_csi_driver_role_arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  configuration_values = jsonencode({
    controller = { nodeSelector = local.system_node_selector, tolerations = local.system_tolerations }
    node       = { tolerations = local.all_workload_node_tolerations }
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
  count                    = var.eks.eks_addons != null && var.eks.eks_addons.enable_fsx_csi_driver && var.eks.create_node_group ? 1 : 0
  cluster_name             = aws_eks_cluster.eks_cluster.name
  addon_name               = "aws-fsx-csi-driver"
  addon_version            = var.eks.eks_addons.fsx_csi_driver_version
  service_account_role_arn = var.eks.eks_addons.fsx_csi_driver_role_key != null ? module.iam_roles[var.eks.eks_addons.fsx_csi_driver_role_key].iam_role_arn : var.eks.eks_addons.fsx_csi_driver_role_arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  configuration_values = jsonencode({
    controller = { nodeSelector = local.system_node_selector, tolerations = local.system_tolerations }
    node       = { tolerations = local.all_workload_node_tolerations }
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
  count                       = var.eks.eks_addons != null && var.eks.eks_addons.enable_privateca_issuer && var.eks.create_node_group ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "aws-privateca-issuer"
  addon_version               = var.eks.eks_addons.privateca_issuer_version
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
  count      = var.eks.eks_addons != null && var.eks.eks_addons.enable_secrets_manager_csi_driver && var.eks.create_node_group ? 1 : 0
  name       = "secrets-provider-aws"
  namespace  = "kube-system"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  version    = var.eks.eks_addons.secrets_manager_csi_driver_aws_provider_version

  cleanup_on_fail = true
  replace         = true
  force_update    = true

  values = [
    yamlencode(merge({
      secrets-store-csi-driver = {
        syncSecret = {
          enabled = true
        }
        enableSecretRotation = var.eks.eks_addons.enableSecretRotation
        rotationPollInterval = var.eks.eks_addons.rotationPollInterval
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
  count      = var.eks.eks_addons != null && var.eks.eks_addons.enable_aws_load_balancer_controller && var.eks.create_node_group ? 1 : 0
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.eks.eks_addons.aws_load_balancer_controller_version

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
          "eks.amazonaws.com/role-arn" = var.eks.eks_addons.aws_load_balancer_controller_role_key != null ? module.iam_roles[var.eks.eks_addons.aws_load_balancer_controller_role_key].iam_role_arn : var.eks.eks_addons.aws_load_balancer_controller_role_arn
        }
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
# NGINX Ingress Controller (Helm) - Tier 3
#--------------------------------------------------------------------
resource "helm_release" "nginx_ingress" {
  for_each   = local.nginx_ingress_enabled ? local.nginx_ingress_map : {}
  name       = each.value.release_name
  namespace  = each.value.namespace
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = each.value.version

  cleanup_on_fail  = true
  replace          = true
  force_update     = true
  create_namespace = true

  values = concat([
    yamlencode({
      controller = {
        replicaCount = each.value.replica_count
        ingressClass = each.value.ingress_class_name
        ingressClassResource = {
          name            = each.value.ingress_class_name
          enabled         = true
          default         = false
          controllerValue = "k8s.io/${each.value.ingress_class_name}-ingress-nginx"
        }
        nodeSelector = local.system_node_selector
        tolerations  = local.system_tolerations
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
      }
      nginx = {
        replicas = local.gateway_api_config.nginx_replicas
        pod = {
          nodeSelector = local.system_node_selector
          tolerations  = local.system_tolerations
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
  count      = var.eks.eks_addons != null && var.eks.eks_addons.enable_cluster_autoscaler && var.eks.create_node_group ? 1 : 0
  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.eks.eks_addons.cluster_autoscaler_version

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
            "eks.amazonaws.com/role-arn" = var.eks.eks_addons.cluster_autoscaler_role_key != null ? module.iam_roles[var.eks.eks_addons.cluster_autoscaler_role_key].iam_role_arn : var.eks.eks_addons.cluster_autoscaler_role_arn
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
  count      = var.eks.eks_addons != null && var.eks.eks_addons.enable_external_dns && var.eks.create_node_group ? 1 : 0
  name       = "external-dns"
  namespace  = var.eks.eks_addons.external_dns_namespace != null ? var.eks.eks_addons.external_dns_namespace : "kube-system"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = var.eks.eks_addons.external_dns_version

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
          "eks.amazonaws.com/role-arn" = var.eks.eks_addons.external_dns_role_key != null ? module.iam_roles[var.eks.eks_addons.external_dns_role_key].iam_role_arn : var.eks.eks_addons.external_dns_role_arn
        }
      }
      policy        = var.eks.eks_addons.external_dns_policy != null ? var.eks.eks_addons.external_dns_policy : "upsert-only"
      txtOwnerId    = aws_eks_cluster.eks_cluster.name
      domainFilters = var.eks.eks_addons.external_dns_domain_filters != null ? var.eks.eks_addons.external_dns_domain_filters : []
      sources       = var.eks.eks_addons.external_dns_sources != null ? var.eks.eks_addons.external_dns_sources : ["service", "ingress"]
      logLevel      = var.eks.eks_addons.external_dns_log_level != null ? var.eks.eks_addons.external_dns_log_level : "info"
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
  count                       = var.eks.eks_addons != null && var.eks.eks_addons.enable_metrics_server && var.eks.create_node_group ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "metrics-server"
  addon_version               = var.eks.eks_addons.metrics_server_version
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
  count = var.eks.eks_addons != null && var.eks.eks_addons.enable_cloudwatch_observability && var.eks.create_node_group && (var.eks.eks_addons.cloudwatch_observability_role_arn != null ||
  var.eks.eks_addons.cloudwatch_observability_role_key != null) ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "amazon-cloudwatch-observability"
  addon_version               = var.eks.eks_addons.cloudwatch_observability_version
  resolve_conflicts_on_update = "PRESERVE"
  service_account_role_arn    = var.eks.eks_addons.cloudwatch_observability_role_key != null ? module.iam_roles[var.eks.eks_addons.cloudwatch_observability_role_key].iam_role_arn : var.eks.eks_addons.cloudwatch_observability_role_arn
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
  count      = var.eks.eks_addons != null && var.eks.eks_addons.enable_fluent_bit && var.eks.create_node_group ? 1 : 0
  name       = "fluent-bit"
  namespace  = var.eks.eks_addons.fluent_bit_namespace != null ? var.eks.eks_addons.fluent_bit_namespace : "amazon-cloudwatch"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = var.eks.eks_addons.fluent_bit_version

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
          "eks.amazonaws.com/role-arn" = var.eks.eks_addons.fluent_bit_role_key != null ? module.iam_roles[var.eks.eks_addons.fluent_bit_role_key].iam_role_arn : var.eks.eks_addons.fluent_bit_role_arn
        }
      }
      config = var.eks.eks_addons.fluent_bit_firehose_delivery_stream != null ? {
        outputs = join("\n", [
          "[OUTPUT]",
          "    Name              kinesis_firehose",
          "    Match             *",
          "    region            ${data.aws_region.current.name}",
          "    delivery_stream   ${var.eks.eks_addons.fluent_bit_firehose_delivery_stream}",
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
  count           = var.eks.eks_addons != null && var.eks.eks_addons.enable_kube_prometheus_stack && var.eks.create_node_group ? 1 : 0
  name            = "kube-prometheus-stack"
  namespace       = var.eks.eks_addons.grafana_namespace != null ? var.eks.eks_addons.grafana_namespace : "monitoring"
  repository      = "https://prometheus-community.github.io/helm-charts"
  chart           = "kube-prometheus-stack"
  version         = var.eks.eks_addons.kube_prometheus_stack_version
  timeout         = var.eks.eks_addons.kube_prometheus_stack_timeout != null ? var.eks.eks_addons.kube_prometheus_stack_timeout : 900
  wait            = true
  atomic          = true
  upgrade_install = var.eks.eks_addons.kube_prometheus_stack_upgrade_install

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
          type = var.eks.eks_addons.grafana_service_type != null ? var.eks.eks_addons.grafana_service_type : "ClusterIP"
        }
        ingress = {
          enabled          = var.eks.eks_addons.grafana_ingress_enabled
          ingressClassName = var.eks.eks_addons.grafana_ingress_class_name
          annotations      = var.eks.eks_addons.grafana_ingress_annotations
          hosts = [
            for host in var.eks.eks_addons.grafana_ingress_hosts : {
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
          enabled          = var.eks.eks_addons.grafana_persistence_enabled
          size             = var.eks.eks_addons.grafana_persistence_size != null ? var.eks.eks_addons.grafana_persistence_size : "10Gi"
          storageClassName = var.eks.eks_addons.grafana_persistence_storage_class
        }
        }, { nodeSelector = local.system_node_selector, tolerations = local.system_tolerations }
      )
      prometheus = {
        prometheusSpec = merge(
          {
            retention = var.eks.eks_addons.prometheus_retention != null ? var.eks.eks_addons.prometheus_retention : "15d"
          },
          var.eks.eks_addons.prometheus_persistence_enabled ? {
            storageSpec = {
              volumeClaimTemplate = {
                spec = {
                  accessModes = ["ReadWriteOnce"]
                  resources = {
                    requests = {
                      storage = var.eks.eks_addons.prometheus_persistence_size != null ? var.eks.eks_addons.prometheus_persistence_size : "20Gi"
                    }
                  }
                  storageClassName = var.eks.eks_addons.prometheus_persistence_storage_class
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
    helm_release.aws_load_balancer_controller
  ]
}

#--------------------------------------------------------------------
# Key Pair Resource for EKS EC2 Node Group
#--------------------------------------------------------------------

resource "tls_private_key" "key" {
  count     = var.eks.create_node_group ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  count      = var.eks.create_node_group ? 1 : 0
  key_name   = var.eks.key_pair.name
  public_key = tls_private_key.key[0].public_key_openssh
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.key_pair.name}"
    }
  )
}

#--------------------------------------------------------------------
# Secrets Manager Secret for EKS EC2 Node Group Key Pair
#--------------------------------------------------------------------

resource "aws_secretsmanager_secret" "private_key_secret" {
  count                          = var.eks.create_node_group ? 1 : 0
  name_prefix                    = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.key_pair.secret_name}"
  description                    = var.eks.key_pair.secret_description
  recovery_window_in_days        = 7
  force_overwrite_replica_secret = true
  policy                         = var.eks.key_pair.policy
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.key_pair.secret_name}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "private_key_secret_version" {
  count         = var.eks.create_node_group ? 1 : 0
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
  for_each = var.eks.create_node_group && var.eks.launch_templates != null ? { for item in var.eks.launch_templates : item.key => item } : {}
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
  for_each = var.eks.create_node_group && var.eks.eks_node_groups != null ? { for item in var.eks.eks_node_groups : item.key => item } : {}
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