# AWS FSx for Windows File System Terraform Module

This Terraform module creates an AWS FSx for Windows File System with comprehensive configuration options.

## Features

- **FSx Windows File System**: Fully managed Windows file system with SMB protocol support
- **Active Directory Integration**: Support for both AWS Managed Microsoft AD and self-managed Active Directory
- **Backup Management**: Automated backup configuration with customizable retention
- **Performance Optimization**: Support for SSD and HDD storage types with configurable IOPS
- **Audit Logging**: Configurable audit logging for file and share access
- **Multi-AZ Support**: Support for single and multi-AZ deployments
- **Flexible Configuration**: All parameters exposed as individual variables

## Usage

### Basic Example

```hcl
module "fsx_windows" {
  source = "./modules/AWSWindows_FSX"

  # Required parameters
  storage_capacity    = 32
  throughput_capacity = 8
  subnet_ids          = ["subnet-12345678"]

  # Optional parameters
  storage_type        = "SSD"
  deployment_type     = "SINGLE_AZ_2"
  active_directory_id = "d-1234567890"
  
  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}
```

### Advanced Example with Self-Managed Active Directory

```hcl
module "fsx_windows_self_managed_ad" {
  source = "./modules/AWSWindows_FSX"

  # Required parameters
  storage_capacity    = 1024
  throughput_capacity = 64
  subnet_ids          = ["subnet-12345678", "subnet-87654321"]

  # Multi-AZ deployment
  deployment_type     = "MULTI_AZ_1"
  preferred_subnet_id = "subnet-12345678"
  storage_type        = "SSD"
  
  # Self-managed Active Directory
  self_managed_active_directory = {
    dns_ips                                = ["10.0.1.100", "10.0.2.100"]
    domain_name                           = "corp.example.com"
    username                              = "Admin"
    password                              = "SecurePassword123!"
    file_system_administrators_group      = "Domain Admins"
    organizational_unit_distinguished_name = "OU=FileSystems,DC=corp,DC=example,DC=com"
  }
    
  # Backup configuration
  automatic_backup_retention_days   = 30
  daily_automatic_backup_start_time = "03:00"
  weekly_maintenance_start_time     = "7:03:00"
  copy_tags_to_backups              = true
  
  # Audit logging
  audit_log_configuration = {
    file_access_audit_log_level       = "SUCCESS_AND_FAILURE"
    file_share_access_audit_log_level = "SUCCESS_AND_FAILURE"
    audit_log_destination             = "arn:aws:logs:us-east-1:123456789012:log-group:fsx-audit-logs"
  }
  
  # Performance tuning for SSD
  disk_iops_configuration = {
    mode = "USER_PROVISIONED"
    iops = 3000
  }

  tags = {
    Environment = "production"
    Project     = "enterprise-file-services"
    Owner       = "IT-Team"
  }
}
```

### HDD Storage Example

```hcl
module "fsx_windows_hdd" {
  source = "./modules/AWSWindows_FSX"

  # Required parameters for HDD (minimum 2000 GiB)
  storage_capacity    = 2000
  throughput_capacity = 16
  subnet_ids          = ["subnet-12345678"]

  # HDD storage configuration
  storage_type        = "HDD"
  deployment_type     = "SINGLE_AZ_2"
  active_directory_id = "d-1234567890"

  tags = {
    Environment = "development"
    Project     = "cost-optimized-storage"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.5 |
| aws | >= 4.37.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.37.0 |

## Inputs

### Required Inputs

| Name | Description | Type |
|------|-------------|------|
| storage_capacity | Storage capacity (GiB) for the file system | `number` |
| throughput_capacity | Throughput capacity (MBps) for the file system | `number` |
| subnet_ids | List of subnet IDs for the file system | `list(string)` |

### Optional Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| storage_type | Storage type (SSD or HDD) | `string` | `"SSD"` |
| deployment_type | Deployment type (SINGLE_AZ_1, SINGLE_AZ_2, MULTI_AZ_1) | `string` | `"SINGLE_AZ_2"` |
| preferred_subnet_id | Preferred subnet ID (required for MULTI_AZ_1) | `string` | `null` |
| security_group_ids | List of security group IDs | `list(string)` | `[]` |
| kms_key_id | ARN for the KMS Key to encrypt the file system | `string` | `null` |
| active_directory_id | AWS Managed Microsoft AD directory ID | `string` | `null` |
| self_managed_active_directory | Self-managed Active Directory configuration | `object` | `null` |
| automatic_backup_retention_days | Number of days to retain automatic backups (0-90) | `number` | `7` |
| daily_automatic_backup_start_time | Daily backup start time (HH:MM) | `string` | `null` |
| weekly_maintenance_start_time | Weekly maintenance start time (d:HH:MM) | `string` | `null` |
| copy_tags_to_backups | Copy tags to backups | `bool` | `true` |
| skip_final_backup | Skip final backup on deletion | `bool` | `false` |
| audit_log_configuration | Audit log configuration | `object` | `null` |
| disk_iops_configuration | Disk IOPS configuration for SSD | `object` | `null` |
| tags | Tags to assign to the file system | `map(string)` | `{}` |
| prevent_destroy | Prevent destruction of the file system | `bool` | `true` |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the FSx Windows file system |
| arn | The ARN of the FSx Windows file system |
| dns_name | The DNS name for the FSx Windows file system |
| network_interface_ids | Set of Elastic Network Interface identifiers |
| owner_id | AWS account identifier that created the file system |
| vpc_id | Identifier of the Virtual Private Cloud for the file system |
| preferred_file_server_ip | The IP address of the primary file server |
| remote_administration_endpoint | Remote administration endpoint for Multi-AZ systems |
| kms_key_id | ARN for the KMS Key to encrypt the file system at rest |

## Important Notes

1. **Lifecycle Protection**: By default, `prevent_destroy = true` to prevent accidental deletion. Set to `false` if needed.

2. **Active Directory**: You can use either AWS Managed Microsoft AD (`active_directory_id`) or self-managed Active Directory (`self_managed_active_directory`), but not both.

3. **Multi-AZ Deployments**: For `MULTI_AZ_1` deployment type, you must specify `preferred_subnet_id`.

4. **Storage Types**: 
   - **SSD**: Better performance, supports provisioned IOPS (minimum 32 GiB)
   - **HDD**: Cost-effective for throughput-intensive workloads (minimum 2000 GiB)

5. **Throughput Capacity**: Valid values are 8, 16, 32, 64, 128, 256, 512, 1024, 2048 MBps.

6. **Security Groups**: You must provide existing security group IDs via `security_group_ids` parameter.

## Validation Rules

The module includes validation rules for:
- Storage capacity minimums (32 GiB for SSD, validation ensures >= 32)
- Throughput capacity values (must be one of the valid options)
- Backup retention days (0-90 days)
- Time format validation for backup and maintenance windows

## Examples Directory

For more comprehensive examples, check the `examples/` directory:

- `basic/` - Minimal FSx configuration
- `multi-az/` - Multi-AZ deployment with high availability
- `with-datasync/` - FSx with DataSync integration
- `self-managed-ad/` - Self-managed Active Directory setup

## License

This module is licensed under the MIT License. See LICENSE file for details.