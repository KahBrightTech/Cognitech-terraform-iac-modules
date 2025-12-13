#-------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Create a flat map: each principal gets its own entry
  access_entries = flatten([
    for group_name, config in var.eks_cluster.access_entries : [
      for principal_arn in config.principal_arns : {
        key           = "${group_name}-${principal_arn}"
        principal_arn = principal_arn
        policy_arn    = config.policy_arn
      }
    ]
  ])
  access_entries_map = { for entry in local.access_entries : entry.key => entry }
}
#--------------------------------------------------------------------
# EKS Cluster
#--------------------------------------------------------------------
resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_cluster.name}-eks-cluster"
  role_arn = var.eks_cluster.role_arn

  vpc_config {
    subnet_ids = var.eks_cluster.subnet_ids
    security_group_ids = concat(
      var.eks_cluster.additional_security_group_ids,
      [for key in var.eks_cluster.additional_security_group_keys : module.security_group[key].security_group_id]
    )
    endpoint_private_access = var.eks_cluster.endpoint_private_access
    endpoint_public_access  = var.eks_cluster.endpoint_public_access
    public_access_cidrs     = var.eks_cluster.public_access_cidrs
  }

  access_config {
    authentication_mode                         = var.eks_cluster.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.eks_cluster.bootstrap_cluster_creator_admin_permissions
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.eks_cluster.service_ipv4_cidr
  }

  enabled_cluster_log_types = var.eks_cluster.enabled_cluster_log_types

  version = var.eks_cluster.version
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_cluster.name}-eks-cluster"
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
  thumbprint_list = [var.eks_cluster.oidc_thumbprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

#--------------------------------------------------------------------
# EKS Networking Add-ons (No nodes required)
#--------------------------------------------------------------------
resource "aws_eks_addon" "vpc_cni" {
  count                       = var.eks_cluster.enable_networking_addons ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_cluster.name}-vpc-cni-addon"
  })
}

resource "aws_eks_addon" "kube_proxy" {
  count                       = var.eks_cluster.enable_networking_addons ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_cluster.name}-kube-proxy-addon"
  })
}

#--------------------------------------------------------------------
# EKS Application Add-ons (Requires nodes to be available)
#--------------------------------------------------------------------

resource "aws_eks_addon" "coredns" {
  count                       = var.eks_cluster.enable_application_addons ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "coredns"
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_cluster.name}-coredns-addon"
  })
}

resource "aws_eks_addon" "metrics_server" {
  count                       = var.eks_cluster.enable_application_addons ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "metrics-server"
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_cluster.name}-metrics-server-addon"
  })
}

resource "aws_eks_addon" "cloudwatch_observability" {
  count                       = var.eks_cluster.enable_application_addons && var.eks_cluster.cloudwatch_observability_role_arn != null ? 1 : 0
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "amazon-cloudwatch-observability"
  resolve_conflicts_on_update = "PRESERVE"
  service_account_role_arn    = var.eks_cluster.cloudwatch_observability_role_arn

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_cluster.name}-cloudwatch-observability-addon"
  })
}

#--------------------------------------------------------------------
# Key Pair Resource
#--------------------------------------------------------------------

resource "tls_private_key" "key" {
  count     = var.eks_cluster.is_this_ec2_node_group ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "aws_key_pair" "generated_key" {
  count      = var.eks_cluster.is_this_ec2_node_group ? 1 : 0
  key_name   = var.eks_cluster.key_pair.name
  public_key = tls_private_key.key[0].public_key_openssh
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_cluster.key_pair.name}"
    }
  )
}


resource "aws_secretsmanager_secret" "private_key_secret" {
  count                          = var.eks_cluster.is_this_ec2_node_group && var.eks_cluster.key_pair.create_secret ? 1 : 0
  name_prefix                    = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_cluster.key_pair.secret_name}"
  description                    = var.eks_cluster.key_pair.secret_description
  recovery_window_in_days        = 7
  force_overwrite_replica_secret = true
  policy                         = var.eks_cluster.key_pair.policy

  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_cluster.key_pair.secret_name}"
    }
  )
}


resource "aws_secretsmanager_secret_version" "private_key_secret_version" {
  count         = var.eks_cluster.is_this_ec2_node_group && var.eks_cluster.key_pair.create_secret ? 1 : 0
  secret_id     = aws_secretsmanager_secret.private_key_secret[0].id
  secret_string = tls_private_key.key[0].private_key_pem
}

module "security_group" {
  for_each       = var.eks_cluster.security_groups != null ? { for item in var.eks_cluster.security_groups : item.key => item } : {}
  source         = "../Security-group"
  common         = var.common
  security_group = each.value
}

module "security_group_rules" {
  source   = "../Security-group-rules"
  for_each = var.eks_cluster.security_group_rules != null ? { for item in var.eks_cluster.security_group_rules : item.sg_key => item } : {}
  common   = var.common
  security_group = {
    security_group_id = each.value.sg_key != null ? module.security_group[each.value.sg_key].security_group_id : each.value.security_group_id
    egress_rules = each.value.egress_rules != null ? [
      for rule in each.value.egress_rules : merge(rule, {
        target_sg_id = rule.target_sg_key != null ? module.security_group[rule.target_sg_key].security_group_id : (
          rule.target_sg_id == "eks_cluster_sg_id" ? aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id : rule.target_sg_id
        )
      })
    ] : null
    ingress_rules = each.value.ingress_rules != null ? [
      for rule in each.value.ingress_rules : merge(rule, {
        source_sg_id = rule.source_sg_key != null ? module.security_group[rule.source_sg_key].security_group_id : (
          rule.source_sg_id == "eks_cluster_sg_id" ? aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id : rule.source_sg_id
        )
      })
    ] : null
  }
  depends_on = [module.security_group]
}
