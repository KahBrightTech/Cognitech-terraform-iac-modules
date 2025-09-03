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
    AL2023 = { pattern = "al2023-ami-*-kernel-6.1-x86_64", owners = ["amazon"] }

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
  ami        = var.ec2.custom_ami != null ? var.ec2.custom_ami : (contains(["W19", "W22"], var.ec2.ami_config.os_release_date) ? local.ami_map[var.ec2.ami_config.os_release_date][var.ec2.ami_config.os_base_packages].pattern : local.ami_map[var.ec2.ami_config.os_release_date].pattern)
  ami_owners = var.ec2.custom_ami != null ? null : (contains(["W19", "W22"], var.ec2.ami_config.os_release_date) ? local.ami_map[var.ec2.ami_config.os_release_date][var.ec2.ami_config.os_base_packages].owners : local.ami_map[var.ec2.ami_config.os_release_date].owners)
}
resource "aws_launch_template" "main" {
  name = var.launch_template.name
  iam_instance_profile {
    name = var.launch_template.instance_profile
  }
  image_id      = data.aws_ami.launch_template.id
  instance_type = var.launch_template.instance_type
  key_name      = var.launch_template.key_name
  network_interfaces {
    associate_public_ip_address = var.launch_template.associate_public_ip_address
  }
  vpc_security_group_ids = var.launch_template.vpc_security_group_ids
  tags                   = var.launch_template.tags
  user_data              = var.launch_template.user_data
}
