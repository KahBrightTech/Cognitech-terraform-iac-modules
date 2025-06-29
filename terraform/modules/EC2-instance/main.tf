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

data "aws_ami" "ec2_instance" {
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
  user_data_map = {
    AL2    = file("${path.module}/user_data/al2.sh")
    AL2023 = file("${path.module}/user_data/al2023.sh")
    RHEL9  = file("${path.module}/user_data/rhel.sh")
    W19    = file("${path.module}/user_data/w19.sh")
  }
  user_data = lookup(local.user_data_map, var.ec2.ami_config.os_release_date, null)
}
#-------------------------------------------------------------------------
# EC2 Instance - Creates an EC2 instance with the specified configuration
#-------------------------------------------------------------------------

resource "aws_instance" "ec2_instance" {
  ami                         = data.aws_ami.ec2_instance.id
  associate_public_ip_address = var.ec2.associate_public_ip_address
  instance_type               = var.ec2.instance_type
  iam_instance_profile        = var.ec2.iam_instance_profile
  key_name                    = var.ec2.key_name
  root_block_device {
    volume_type           = var.ec2.ebs_root_volume.volume_type
    volume_size           = var.ec2.ebs_root_volume.volume_size
    delete_on_termination = var.ec2.ebs_root_volume.delete_on_termination
    encrypted             = var.ec2.ebs_root_volume.encrypted
    kms_key_id            = var.ec2.ebs_root_volume.kms_key_id
    tags = merge(var.common.tags, {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.ec2.name}-ebs-root"
    })
  }
  subnet_id = var.ec2.subnet_id
  tags = merge(
    var.common.tags,
    var.ec2.custom_tags,
    {
      Schedule = var.ec2.Schedule_name != null ? var.ec2.Schedule_name : "default"
      Backup   = var.ec2.backup_plan_name != null ? var.ec2.backup_plan_name : "default"
      Name     = var.ec2.name_override != null ? var.ec2.name_override : "${var.common.account_name}-${var.common.region_prefix}-ec2-${var.ec2.name}"

    }
  )
  user_data              = local.user_data
  vpc_security_group_ids = var.ec2.security_group_ids
  lifecycle {
    ignore_changes = [
      root_block_device[0].volume_type,
      root_block_device[0].volume_size,
      root_block_device[0].delete_on_termination,
      root_block_device[0].encrypted,
      root_block_device[0].kms_key_id,
      ami,
      user_data
    ]
  }
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    http_endpoint               = "enabled"
  }
}
#-------------------------------------------------------------------------
# EBS Volume - Creates an EBS volume with the specified configuration
#-------------------------------------------------------------------------
resource "aws_ebs_volume" "ebs_volume" {
  availability_zone = aws_instance.ec2_instance.availability_zone # Creates the EBS volume in the same AZ as the EC2 instance
  size              = var.ec2.ebs_device_volume.volume_size
  type              = var.ec2.ebs_device_volume.volume_type
  encrypted         = var.ec2.ebs_device_volume.encrypted
  kms_key_id        = var.ec2.ebs_device_volume.kms_key_id

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.ec2.name}-ebs-volume"
  })

}

#-------------------------------------------------------------------------
# EBS Volume Attachment - Attaches the EBS volume to the EC2 instance
#-------------------------------------------------------------------------
resource "aws_volume_attachment" "ebs_volume_attachment" {
  for_each                       = { for ebs in var.ec2.ebs_device_volume : ebs.name => ebs }
  device_name                    = each.value.name # Specify the device name for the EBS volume attachment
  volume_id                      = aws_ebs_volume.ebs_volume[each.value.name].id
  instance_id                    = aws_instance.ec2_instance.id
  skip_destroy                   = false # Set to true if you want to skip the destroy operation for this resource 
  stop_instance_before_detaching = true  # Set to true if you want to stop the instance before detaching the volume
}


