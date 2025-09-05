#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
# data source to get AZ from instance
data "aws_instance" "target" {
  instance_id = var.ebs_restore.instance_id
}

# Local values for device naming logic
locals {
  # Device name prefix based on OS type variable
  device_prefix = var.ebs_restore.os_type == "windows" ? "/dev/xvd" : "xvd"

  # Create a map of volumes using loop starting from specified letter
  volumes = {
    for i in range(var.ebs_restore.volume_count) : "volume_${i + 1}" => {
      device_letter = substr("abcdefghijklmnopqrstuvwxyz",
      index(split("", "abcdefghijklmnopqrstuvwxyz"), var.ebs_restore.starting_letter) + i, 1)
      size = var.ebs_restore.volume_size
    }
  }
}

#--------------------------------------------------------------------
# Restores EBS Volume
#--------------------------------------------------------------------

# New volumes with for_each
resource "aws_ebs_volume" "new" {
  for_each = local.volumes

  availability_zone = data.aws_instance.target.availability_zone
  size              = each.value.size

  tags = merge(var.common.tags, {
    Name = "${each.key}-volume"
  })
}

# Stop instance before detach/attach
resource "aws_ec2_instance_state" "stop_instance" {
  instance_id = var.ebs_restore.instance_id
  state       = "stopped"
}

# Attach new volumes with OS-aware device naming
resource "aws_volume_attachment" "new_attach" {
  for_each = local.volumes

  device_name  = "${local.device_prefix}${each.value.device_letter}"
  volume_id    = aws_ebs_volume.new[each.key].id
  instance_id  = var.ebs_restore.instance_id
  force_detach = true

  depends_on = [aws_ec2_instance_state.stop_instance]
}

# Start instance again after swap
resource "aws_ec2_instance_state" "start_instance" {
  instance_id = var.ebs_restore.instance_id
  state       = "running"

  depends_on = [aws_volume_attachment.new_attach]
}