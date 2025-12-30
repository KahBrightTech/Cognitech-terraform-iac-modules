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
        key           = "${group_name}-${principal_arn}"
        principal_arn = principal_arn
        policy_arn    = config.policy_arn
      }
    ]
  ])
  access_entries_map = { for entry in local.access_entries : entry.key => entry }
  admin_role_arn     = length(data.aws_iam_roles.admin_role.arns) > 0 ? sort(data.aws_iam_roles.admin_role.arns)[0] : ""
  network_role_arn   = length(data.aws_iam_roles.network_role.arns) > 0 ? sort(data.aws_iam_roles.network_role.arns)[0] : ""
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

  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = each.value.principal_arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "access_policy" {
  for_each = local.access_entries_map

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
# EKS Addons
#--------------------------------------------------------------------
resource "aws_eks_addon" "vpc_cni" {
  count                       = var.eks.eks_addons != null && var.eks.eks_addons.enable_vpc_cni ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "vpc-cni"
  addon_version               = var.eks.eks_addons.vpc_cni_version
  resolve_conflicts_on_update = "PRESERVE"

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

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.key}-kube-proxy-addon"
  })
}

resource "aws_eks_addon" "coredns" {
  count                       = var.eks.eks_addons != null && var.eks.eks_addons.enable_coredns && var.eks.create_node_group ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "coredns"
  addon_version               = var.eks.eks_addons.coredns_version
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.key}-coredns-addon"
  })
  depends_on = [module.eks_node_group]
}

resource "aws_eks_addon" "metrics_server" {
  count                       = var.eks.eks_addons != null && var.eks.eks_addons.enable_metrics_server && var.eks.create_node_group ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "metrics-server"
  addon_version               = var.eks.eks_addons.metrics_server_version
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.key}-metrics-server-addon"
  })
  depends_on = [module.eks_node_group]
}

resource "aws_eks_addon" "cloudwatch_observability" {
  count = var.eks.eks_addons != null && var.eks.eks_addons.enable_cloudwatch_observability && var.eks.create_node_group && (var.eks.eks_addons.cloudwatch_observability_role_arn != null ||
  var.eks.eks_addons.cloudwatch_observability_role_key != null) ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "amazon-cloudwatch-observability"
  addon_version               = var.eks.eks_addons.cloudwatch_observability_version
  resolve_conflicts_on_update = "PRESERVE"
  service_account_role_arn    = var.eks.eks_addons.cloudwatch_observability_role_arn

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.key}-cloudwatch-observability-addon"
  })
  depends_on = [module.eks_node_group]
}

resource "aws_eks_addon" "ebs_csi_driver" {
  count                    = var.eks.eks_addons != null && var.eks.eks_addons.enable_ebs_csi_driver && var.eks.create_node_group ? 1 : 0
  cluster_name             = aws_eks_cluster.eks_cluster.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.eks.eks_addons.ebs_csi_driver_version
  service_account_role_arn = var.eks.eks_addons.ebs_csi_driver_role_key != null ? module.iam_roles[var.eks.eks_addons.ebs_csi_driver_role_key].iam_role_arn : var.eks.eks_addons.ebs_csi_driver_role_arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  depends_on = [
    module.eks_node_group,
    module.iam_roles
  ]
}
resource "aws_eks_addon" "privateca_issuer" {
  count                       = var.eks.eks_addons != null && var.eks.eks_addons.enable_privateca_issuer && var.eks.create_node_group ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "aws-privateca-issuer"
  addon_version               = var.eks.eks_addons.privateca_issuer_version
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks.key}-privateca-issuer-addon"
  })
  depends_on = [module.eks_node_group]
}

resource "aws_eks_addon" "pod_identity_agent" {
  count         = var.eks.eks_addons != null && var.eks.eks_addons.enable_pod_identity_agent && var.eks.create_node_group ? 1 : 0
  cluster_name  = aws_eks_cluster.eks_cluster.name
  addon_name    = "eks-pod-identity-agent"
  addon_version = var.eks.eks_addons.pod_identity_agent_version

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "helm_release" "secrets_store_aws_provider" {
  count     = var.eks.eks_addons != null && var.eks.eks_addons.enable_secrets_manager_csi_driver && var.eks.create_node_group ? 1 : 0
  name      = "secrets-provider-aws"
  namespace = "kube-system"

  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  version    = var.eks.eks_addons.secrets_manager_csi_driver_aws_provider_version

  cleanup_on_fail = true
  replace         = true
  force_update    = true

  values = [
    yamlencode({
      secrets-store-csi-driver = {
        syncSecret = {
          enabled = true
        }
        enableSecretRotation = var.eks.eks_addons.enableSecretRotation
        rotationPollInterval = var.eks.eks_addons.rotationPollInterval
      }
    })
  ]

  depends_on = [module.eks_node_group]
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
          for sg_key in each.value.vpc_security_group_keys : module.security_group[sg_key].security_group_id
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
  depends_on = [aws_eks_cluster.eks_cluster]
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
  for_each        = var.eks.enable_eks_pia && var.eks.eks_pia != null ? { for item in var.eks.eks_pia : item.key => item } : {}
  cluster_name    = aws_eks_cluster.eks_cluster.name
  namespace       = each.value.service_account_namespace
  service_account = each.value.service_account_keys != null ? module.service_account[each.key].service_account_name : each.value.service_account_name
  role_arn        = each.value.role_key != null ? module.iam_roles[each.value.role_key].iam_role_arn : each.value.role_arn
  depends_on      = [aws_eks_cluster.eks_cluster]
}
