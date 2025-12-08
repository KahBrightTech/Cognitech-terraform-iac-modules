#--------------------------------------------------------------------
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
# Get stable role ARNs using sort() to ensure consistent ordering
#--------------------------------------------------------------------
# Create Launch Template
#--------------------------------------------------------------------
#--------------------------------------------------------------------
# Locals
#--------------------------------------------------------------------

locals {
  ami_map = {
    # Amazon Linux AMIs
    AL2    = { pattern = "amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2", owners = ["amazon"] }
    AL2023 = { pattern = "al2023-ami-2023.*-kernel-6.1-x86_64", owners = ["amazon"] }

    # EKS Optimized AMIs
    EKSAL2    = { pattern = "amazon-eks-node-*", owners = ["amazon"] }
    EKSAL2023 = { pattern = "amazon-eks-node-al2023-x86_64-standard-*", owners = ["amazon"] }

    # Red Hat Enterprise Linux AMIs
    RHEL9  = { pattern = "RHEL-9.6.0_HVM_*-x86_64-*-Hourly2-GP3", owners = ["amazon"] }
    RHEL10 = { pattern = "RHEL-10.0.0_HVM_*-x86_64-*-Hourly2-GP3", owners = ["amazon"] }

    #Windows 2019 AMIs
    W19 = {
      BASE   = { pattern = "Windows_Server-2019-English-Full-Base-*", owners = ["amazon"] }
      SQLE19 = { pattern = "Windows_Server-2019-English-Full-SQL_2019_Enterprise-*", owners = ["amazon"] }
    }
    #Windows 2022 AMIs
    W22 = {
      BASE   = { pattern = "Windows_Server-2022-English-Full-Base-*", owners = ["amazon"] }
      SQLE22 = { pattern = "Windows_Server-2022-English-Full-SQL_2022_Enterprise-*", owners = ["amazon"] }
    }
    #Windows 2025 AMIs
    W25 = {
      BASE = { pattern = "Windows_Server-2025-English-Full-Base-*", owners = ["amazon"] }
    }
    #Ubuntu AMIs
    UBUNTU20 = { pattern = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*", owners = ["amazon"] }
  }
  ami        = var.launch_template.custom_ami != null ? var.launch_template.custom_ami : (contains(["W19", "W22"], var.launch_template.ami_config.os_release_date) ? local.ami_map[var.launch_template.ami_config.os_release_date][var.launch_template.ami_config.os_base_packages].pattern : local.ami_map[var.launch_template.ami_config.os_release_date].pattern)
  ami_owners = var.launch_template.custom_ami != null ? null : (contains(["W19", "W22"], var.launch_template.ami_config.os_release_date) ? local.ami_map[var.launch_template.ami_config.os_release_date][var.launch_template.ami_config.os_base_packages].owners : local.ami_map[var.launch_template.ami_config.os_release_date].owners)
}
resource "aws_launch_template" "main" {
  name = var.launch_template.name
  iam_instance_profile {
    name = var.launch_template.instance_profile
  }
  image_id      = data.aws_ami.launch_template.id
  instance_type = var.launch_template.instance_type
  key_name      = var.launch_template.key_name
  # network_interfaces {
  #   associate_public_ip_address = var.launch_template.network_interfaces.associate_public_ip_address
  #   security_groups             = var.launch_template.network_interfaces.security_groups
  #   delete_on_termination       = var.launch_template.network_interfaces.delete_on_termination
  # }
  vpc_security_group_ids = var.launch_template.vpc_security_group_ids

  dynamic "user_data" {
    for_each = var.launch_template.user_data == null ? [] : [1]
    content {
      user_data = base64encode(var.launch_template.user_data)
    }
  }

  dynamic "block_device_mappings" {
    for_each = var.launch_template.volume_size != null ? [1] : []
    content {
      device_name = var.launch_template.root_device_name
      ebs {
        volume_size           = var.launch_template.volume_size
        volume_type           = "gp3"
        delete_on_termination = true
        encrypted             = true
      }
    }
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.launch_template.name}-lt"
  })
}
