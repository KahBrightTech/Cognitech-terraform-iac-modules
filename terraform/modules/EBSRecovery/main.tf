#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
# Lookup the destination instance (different from source)
data "aws_instance" "target" {
  filter {
    name   = "tag:Name"
    values = [var.dr_volume_restore.target_instance_name]
  }
}
locals {
  # Convert list of objects into a map keyed by device_name
  device_config = {
    for volume in var.dr_volume_restore.device_volumes : volume.device_name => volume
  }
}


# Lookup the most recent snapshot for each device on the source instance
data "aws_ebs_snapshot" "latest_by_device" {
  for_each    = local.device_config
  most_recent = true

  filter {
    name   = "tag:Name"
    values = [var.dr_volume_restore.source_instance_name]
  }

  filter {
    name   = "tag:DeviceName"
    values = [each.value.device_name]
  }

  owners = [var.dr_volume_restore.account_id]
}

# Stop the destination instance before restoring volumes (conditional)
resource "aws_ec2_instance_state" "stop_target" {
  count       = var.dr_volume_restore.stop_instance ? 1 : 0
  instance_id = data.aws_instance.target.id
  state       = "stopped"
}

# Restore volumes from snapshots
resource "aws_ebs_volume" "restored" {
  for_each = data.aws_ebs_snapshot.latest_by_device

  availability_zone = var.dr_volume_restore.target_az
  snapshot_id       = each.value.id
  type              = "gp3"
  # Use specified size if provided, otherwise use snapshot size
  size = local.device_config[each.key].size != null ? local.device_config[each.key].size : null

  tags = merge(
    {
      Name        = var.dr_volume_restore.source_instance_name
      RestoredFor = var.dr_volume_restore.source_instance_name
      DeviceName  = local.device_config[each.key].device_name
    },
    var.dr_volume_restore.restore_volume_tags
  )
}

# Attach restored volumes to the target instance
resource "aws_volume_attachment" "attach_restored" {
  for_each = aws_ebs_volume.restored

  device_name = local.device_config[each.key].device_name
  volume_id   = each.value.id
  instance_id = data.aws_instance.target.id

  depends_on = [
    aws_ebs_volume.restored
  ]
}

# Start the target instance once all volumes are attached (conditional)
resource "aws_ec2_instance_state" "start_target" {
  count       = var.dr_volume_restore.stop_instance ? 1 : 0
  instance_id = data.aws_instance.target.id
  state       = "running"

  depends_on = [aws_volume_attachment.attach_restored]
}



