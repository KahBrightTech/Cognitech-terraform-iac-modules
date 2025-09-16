# EBS Recovery Module

This module provides disaster recovery functionality for EBS volumes by restoring volumes from snapshots to a target EC2 instance.

## Features

- Restores EBS volumes from snapshots to a target instance
- Supports device configurations with custom sizes
- Automatically stops the target instance before volume restoration
- Automatically starts the target instance after all volumes are attached
- Flexible volume sizing (use snapshot size or specify custom size)

## Usage

```hcl
module "ebs_recovery" {
  source = "./modules/EBSRecovery"

  common = var.common

  dr_volume_restore = {
    source_instance_name = "source-instance-name"
    target_instance_name = "target-instance-name"
    target_az            = "us-west-2a"
    device_volumes = {
      "volume1" = {
        device_name = "/dev/sdf"
        size        = 100  # GB - will resize the volume to 100GB
      }
      "volume2" = {
        device_name = "/dev/sdg"
        size        = 200  # GB - will resize the volume to 200GB
      }
      "volume3" = {
        device_name = "/dev/sdh"
        # size not specified - will use the original snapshot size
      }
    }
    restore_volume_tags = {
      Environment = "production"
      Backup      = "true"
    }
    account_id = "123456789012"
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| common | Common variables used by all resources | `object` | n/a | yes |
| dr_volume_restore | Disaster Recovery Volume Restore configuration | `object` | `null` | yes |

### dr_volume_restore object

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Optional name for the restore operation | `string` | `null` | no |
| source_instance_name | Name of the source instance (tagged in snapshots) | `string` | n/a | yes |
| target_instance_name | Name of the target instance to restore volumes to | `string` | n/a | yes |
| target_az | Availability zone where volumes will be created | `string` | n/a | yes |
| device_volumes | Map of device configurations with optional sizes | `map(object)` | n/a | yes |
| restore_volume_tags | Tags to apply to restored volumes | `map(string)` | n/a | yes |
| account_id | AWS account ID that owns the snapshots | `string` | n/a | yes |

### device_volumes object

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| device_name | Device name (e.g., "/dev/sdf") | `string` | n/a | yes |
| size | Volume size in GB (if not specified, uses snapshot size) | `number` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| restored_volume_ids | Map of device names to restored EBS volume IDs |
| restored_volume_arns | Map of device names to restored EBS volume ARNs |
| restored_volumes | Complete details of all restored EBS volumes |
| target_instance_id | ID of the target instance where volumes were restored |
| volume_attachments | Map of device names to volume attachment details |

## Prerequisites

1. The source instance must have been properly tagged in the EBS snapshots
2. Snapshots must have the following tags:
   - `Name`: Must match the `source_instance_name`
   - `DeviceName`: Must match the device names specified in the configuration
3. The target instance must exist and be tagged with the `target_instance_name`
4. The target instance must be in the same region as the target AZ

## Notes

- The module will automatically stop the target instance before attaching volumes
- The module will automatically start the target instance after all volumes are attached
- If using `device_volumes` with custom sizes, the size must be equal to or larger than the snapshot size
- The module uses GP3 volume type by default for restored volumes