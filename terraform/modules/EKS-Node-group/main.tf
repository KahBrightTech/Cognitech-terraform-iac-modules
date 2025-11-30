#-------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_ami" "launch_template" {
  most_recent        = true
  include_deprecated = true
  owners             = local.ami_owners

  filter {
    name   = "name"
    values = ["${local.ami}"]
  }
}
#--------------------------------------------------------------------
# Locals
#--------------------------------------------------------------------

locals {
  ami_map = {
    # Amazon Linux AMIs
    AL2    = { pattern = "amazon-eks-node-*", owners = ["amazon"] }
    AL2023 = { pattern = "amazon-eks-node-al2023-x86_64-standard-*", owners = ["amazon"] }
  }
  ami        = var.eks_node_group.launch_template.custom_ami != null ? var.eks_node_group.launch_template.custom_ami : local.ami_map[var.eks_node_group.launch_template.ami_config.os_release_date].pattern
  ami_owners = var.eks_node_group.launch_template.custom_ami != null ? null : local.ami_map[var.eks_node_group.launch_template.ami_config.os_release_date].owners
}
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
    ec2_ssh_key               = var.eks_node_group.ec2_ssh_key
    source_security_group_ids = var.eks_node_group.source_security_group_ids
  }

  ami_type             = var.eks_node_group.ami_type
  disk_size            = var.eks_node_group.disk_size
  labels               = var.eks_node_group.labels
  tags                 = var.eks_node_group.tags
  version              = var.eks_node_group.version
  force_update_version = var.eks_node_group.force_update_version
  capacity_type        = var.eks_node_group.capacity_type
  dynamic "launch_template" {
    for_each = var.eks_node_group.launch_template != null ? [1] : []
    content {
      id      = aws_launch_template.main[0].id
      version = var.eks_node_group.launch_template_version
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

#--------------------------------------------------------------------
# Create Launch Template
#--------------------------------------------------------------------
resource "aws_launch_template" "main" {
  count = var.eks_node_group.launch_template != null ? 1 : 0
  name  = var.eks_node_group.launch_template.name
  iam_instance_profile {
    name = var.eks_node_group.launch_template.instance_profile
  }
  image_id               = data.aws_ami.launch_template.id
  instance_type          = var.eks_node_group.launch_template.instance_type
  key_name               = var.eks_node_group.launch_template.key_name
  vpc_security_group_ids = var.eks_node_group.launch_template.vpc_security_group_ids
  user_data              = base64encode(var.eks_node_group.launch_template.user_data)
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_node_group.launch_template.name}-lt"
  })
}
