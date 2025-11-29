#-------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#--------------------------------------------------------------------
# EKS Cluster
#--------------------------------------------------------------------
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.eks_cluster.name
  role_arn = var.eks_cluster.role_arn

  vpc_config {
    subnet_ids = var.eks_cluster.subnet_ids
  }

  version = var.eks_cluster.version
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_cluster.name}-eks-cluster"
  })
}

#--------------------------------------------------------------------
# OIDC Provider for EKS Cluster
#--------------------------------------------------------------------
resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.eks_cluster.oidc_thumbprints
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
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
  count         = var.eks_cluster.is_this_ec2_node_group && var.eks_cluster.key_pair.key_pair.create_secret ? 1 : 0
  secret_id     = aws_secretsmanager_secret.private_key_secret[0].id
  secret_string = tls_private_key.key[0].private_key_pem
}