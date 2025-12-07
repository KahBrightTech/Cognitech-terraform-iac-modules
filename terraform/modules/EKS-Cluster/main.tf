#-------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
#--------------------------------------------------------------------
# EKS Cluster
#--------------------------------------------------------------------
resource "aws_eks_cluster" "eks_cluster" {
  name     = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_cluster.name}-eks-cluster"
  role_arn = var.eks_cluster.role_arn

  vpc_config {
    subnet_ids              = var.eks_cluster.subnet_ids
    endpoint_private_access = var.eks_cluster.endpoint_private_access
    endpoint_public_access  = var.eks_cluster.endpoint_public_access
    public_access_cidrs     = var.eks_cluster.public_access_cidrs
  }

  access_config {
    authentication_mode                         = var.eks_cluster.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.eks_cluster.bootstrap_cluster_creator_admin_permissions
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
resource "aws_eks_access_entry" "admin_role" {
  for_each = toset(var.eks_cluster.principal_arns)

  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = each.value
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin_policy" {
  for_each = toset(var.eks_cluster.principal_arns)

  cluster_name  = aws_eks_cluster.eks_cluster.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin_role]
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