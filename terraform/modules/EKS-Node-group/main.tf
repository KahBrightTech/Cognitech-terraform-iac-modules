#-------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#--------------------------------------------------------------------
# EKS Node Group
#--------------------------------------------------------------------
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = var.eks_node_group.cluster_name
  node_group_name = var.eks_node_group.node_group_name
  node_role_arn   = var.eks_node_group.node_role_arn
  subnet_ids      = var.eks_node_group.subnet_ids

  scaling_config {
    desired_size = var.eks_node_group.desired_size
    max_size     = var.eks_node_group.max_size
    min_size     = var.eks_node_group.min_size
  }

  instance_types = var.eks_node_group.instance_types

  remote_access {
    ec2_ssh_key               = var.eks_node_group.launch_template != null ? null : var.eks_node_group.ec2_ssh_key
    source_security_group_ids = var.eks_node_group.launch_template != null ? null : var.eks_node_group.source_security_group_ids
  }

  ami_type             = var.eks_node_group.ami_type
  disk_size            = var.eks_node_group.launch_template != null ? null : var.eks_node_group.disk_size
  labels               = var.eks_node_group.labels
  tags                 = var.eks_node_group.tags
  version              = var.eks_node_group.version
  force_update_version = var.eks_node_group.force_update_version
  capacity_type        = var.eks_node_group.capacity_type

  dynamic "launch_template" {
    for_each = var.eks_node_group.launch_template != null ? [var.eks_node_group.launch_template] : []
    content {
      id      = launch_template.value.id
      version = launch_template.value.version
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

