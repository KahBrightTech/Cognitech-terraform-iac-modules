# AWS EFS Terraform Module

This module creates an Amazon Elastic File System (EFS) with configurable mount targets and access points.

## Features

- **EFS File System**: Creates an encrypted EFS file system with configurable performance and throughput modes
- **Mount Targets**: Automatically creates mount targets in specified subnets
- **Access Points**: Configurable access points for fine-grained access control
- **Lifecycle Policies**: Optional lifecycle policies for cost optimization
- **Security Groups**: Configurable security groups for mount targets

## Usage

```hcl
module "efs" {
  source = "./modules/AWSEFS"
  
  efs = {
    name           = "my-application-efs"
    creation_token = "my-app-efs-2024"
    subnet_ids     = ["subnet-12345", "subnet-67890"]
    security_group_ids = ["sg-12345"]
    
    # Optional: Configure performance settings
    performance_mode = "generalPurpose"  # or "maxIO"
    throughput_mode  = "bursting"        # or "provisioned"
    encrypted        = true
    
    # Optional: Lifecycle policy for cost optimization
    lifecycle_policy = {
      transition_to_ia = "AFTER_30_DAYS"
    }
    
    # Optional: Access points for different applications
    access_points = {
      app1 = {
        name = "app1-access-point"
        posix_user = {
          gid = 1000
          uid = 1000
        }
        root_directory = {
          path = "/app1"
          creation_info = {
            owner_gid   = 1000
            owner_uid   = 1000
            permissions = "0755"
          }
        }
        tags = {
          Application = "app1"
        }
      }
      app2 = {
        name = "app2-access-point"
        posix_user = {
          gid = 2000
          uid = 2000
        }
        root_directory = {
          path = "/app2"
          creation_info = {
            owner_gid   = 2000
            owner_uid   = 2000
            permissions = "0755"
          }
        }
      }
    }
    
    tags = {
      Environment = "production"
      Project     = "my-project"
      Owner       = "platform-team"
    }
  }
}
```

## Variable Reference

### `efs` Object

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the EFS file system | `string` | - | yes |
| creation_token | Unique creation token for the EFS | `string` | - | yes |
| subnet_ids | List of subnet IDs for mount targets | `list(string)` | - | yes |
| security_group_ids | List of security group IDs for mount targets | `list(string)` | - | yes |
| performance_mode | EFS performance mode | `string` | `"generalPurpose"` | no |
| throughput_mode | EFS throughput mode | `string` | `"bursting"` | no |
| provisioned_throughput_in_mibps | Provisioned throughput in MiB/s (required if throughput_mode is "provisioned") | `number` | `null` | no |
| encrypted | Whether to encrypt the EFS | `bool` | `true` | no |
| kms_key_id | KMS key ID for encryption | `string` | `null` | no |
| lifecycle_policy | Lifecycle policy configuration | `object` | `null` | no |
| access_points | Map of access point configurations | `map(object)` | `{}` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

### Performance Mode Options
- `generalPurpose`: Default mode with lower latency per operation
- `maxIO`: Higher levels of aggregate throughput and operations per second

### Throughput Mode Options
- `bursting`: Default mode that scales with file system size
- `provisioned`: Fixed amount of throughput independent of file system size

### Lifecycle Policy Options
- `transition_to_ia`: When to transition files to Infrequent Access storage class
  - `AFTER_7_DAYS`
  - `AFTER_14_DAYS`
  - `AFTER_30_DAYS`
  - `AFTER_60_DAYS`
  - `AFTER_90_DAYS`

## Outputs

| Name | Description |
|------|-------------|
| efs_file_system_id | The ID of the EFS file system |
| efs_file_system_arn | The ARN of the EFS file system |
| efs_file_system_dns_name | The DNS name of the EFS file system |
| efs_creation_token | The creation token of the EFS file system |
| efs_mount_target_ids | Map of subnet IDs to mount target IDs |
| efs_mount_target_dns_names | Map of subnet IDs to mount target DNS names |
| efs_mount_target_network_interface_ids | Map of subnet IDs to network interface IDs |
| efs_access_point_ids | Map of access point names to IDs |
| efs_access_point_arns | Map of access point names to ARNs |
| efs | Complete EFS configuration and attributes |

## Examples

### Basic EFS with Mount Targets

```hcl
module "basic_efs" {
  source = "./modules/AWSEFS"
  
  efs = {
    name           = "basic-efs"
    creation_token = "basic-efs-token"
    subnet_ids     = ["subnet-12345", "subnet-67890"]
    security_group_ids = ["sg-efs-access"]
    
    tags = {
      Environment = "dev"
    }
  }
}
```

### High Performance EFS with Provisioned Throughput

```hcl
module "high_performance_efs" {
  source = "./modules/AWSEFS"
  
  efs = {
    name           = "high-perf-efs"
    creation_token = "high-perf-efs-token"
    subnet_ids     = ["subnet-12345", "subnet-67890"]
    security_group_ids = ["sg-efs-access"]
    
    performance_mode = "maxIO"
    throughput_mode  = "provisioned"
    provisioned_throughput_in_mibps = 500
    
    tags = {
      Environment = "production"
      Performance = "high"
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Security Considerations

1. **Encryption**: The module enables encryption by default. Consider using a customer-managed KMS key for enhanced security.
2. **Security Groups**: Ensure security groups restrict access to only necessary sources and ports (NFS port 2049).
3. **Access Points**: Use access points to enforce POSIX permissions and user/group ownership.
4. **VPC**: Deploy EFS in private subnets when possible to limit exposure.

## Mount Instructions

To mount the EFS file system on an EC2 instance:

```bash
# Install EFS utilities (Amazon Linux 2)
sudo yum install -y amazon-efs-utils

# Create mount point
sudo mkdir /mnt/efs

# Mount using EFS file system ID
sudo mount -t efs fs-12345678:/ /mnt/efs

# Mount using DNS name
sudo mount -t efs fs-12345678.efs.us-west-2.amazonaws.com:/ /mnt/efs

# Mount using access point
sudo mount -t efs -o tls,accesspoint=fsap-12345678 fs-12345678:/ /mnt/efs
```

For persistent mounting, add to `/etc/fstab`:

```
fs-12345678.efs.us-west-2.amazonaws.com:/ /mnt/efs efs defaults,_netdev 0 0
```