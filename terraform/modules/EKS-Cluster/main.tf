#--------------------------------------------------------------------
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


