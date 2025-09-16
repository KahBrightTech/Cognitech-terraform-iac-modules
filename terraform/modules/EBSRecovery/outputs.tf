# Output the volume IDs (both restored and resized)
output "volume_ids" {
  description = "Map of device names to EBS volume IDs"
  value = merge(
    {
      for device_name, volume in aws_ebs_volume.restored : device_name => volume.id
    },
    {
      for device_name, volume in aws_ebs_volume.resized : device_name => volume.id
    }
  )
}

# Output the volume ARNs (both restored and resized)
output "volume_arns" {
  description = "Map of device names to EBS volume ARNs"
  value = merge(
    {
      for device_name, volume in aws_ebs_volume.restored : device_name => volume.arn
    },
    {
      for device_name, volume in aws_ebs_volume.resized : device_name => volume.arn
    }
  )
}

# Output all volume details for reference (both restored and resized)
output "volumes" {
  description = "Complete details of all EBS volumes"
  value = merge(
    {
      for device_name, volume in aws_ebs_volume.restored : device_name => {
        id                = volume.id
        arn               = volume.arn
        availability_zone = volume.availability_zone
        size              = volume.size
        type              = volume.type
        encrypted         = volume.encrypted
        snapshot_id       = volume.snapshot_id
        operation_type    = "restored"
      }
    },
    {
      for device_name, volume in aws_ebs_volume.resized : device_name => {
        id                = volume.id
        arn               = volume.arn
        availability_zone = volume.availability_zone
        size              = volume.size
        type              = volume.type
        encrypted         = volume.encrypted
        operation_type    = "resized"
      }
    }
  )
}

# Output the target instance ID that volumes were attached to
output "target_instance_id" {
  description = "ID of the target instance where volumes were restored"
  value       = data.aws_instance.target.id
}

# Output the volume attachment information
output "volume_attachments" {
  description = "Map of device names to volume attachment details"
  value = {
    for device_name, attachment in aws_volume_attachment.attach_restored : device_name => {
      device_name = attachment.device_name
      volume_id   = attachment.volume_id
      instance_id = attachment.instance_id
    }
  }
}
