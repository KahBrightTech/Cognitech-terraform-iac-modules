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

# Lookup the most recent snapshot for each device on the source instance
data "aws_ebs_snapshot" "latest_by_device" {
  for_each    = toset(var.dr_volume_restore.device_names) # list of devices
  most_recent = true

  filter {
    name   = "tag:Name"
    values = [var.dr_volume_restore.source_instance_name]
  }

  filter {
    name   = "tag:DeviceName"
    values = [each.value]
  }

  owners = [var.dr_volume_restore.account_id]
}

# Stop the destination instance before restoring volumes
resource "aws_ec2_instance_state" "stop_target" {
  instance_id = data.aws_instance.target.id
  state       = "stopped"
}

# Restore volumes from snapshots
resource "aws_ebs_volume" "restored" {
  for_each = data.aws_ebs_snapshot.latest_by_device

  availability_zone = var.dr_volume_restore.target_az
  snapshot_id       = each.value.id
  type              = "gp3"

  tags = merge(
    {
      Name        = var.dr_volume_restore.source_instance_name
      RestoredFor = var.dr_volume_restore.source_instance_name
      DeviceName  = data.aws_ebs_snapshot.latest_by_device[each.key].tags["DeviceName"]
    },
    var.dr_volume_restore.restore_volume_tags
  )
}

# Attach restored volumes to the target instance
resource "aws_volume_attachment" "attach_restored" {
  for_each = aws_ebs_volume.restored

  device_name = data.aws_ebs_snapshot.latest_by_device[each.key].tags["DeviceName"]
  volume_id   = each.value.id
  instance_id = data.aws_instance.target.id

  depends_on = [
    aws_ec2_instance_state.stop_target,
    aws_ebs_volume.restored[each.key]
  ]
}

# Start the target instance once all volumes are attached
resource "aws_ec2_instance_state" "start_target" {
  instance_id = data.aws_instance.target.id
  state       = "running"

  depends_on = [aws_volume_attachment.attach_restored]
}



