# AWS DataSync Terraform Module

This Terraform module creates AWS DataSync resources including multiple location types and tasks with optional scheduling. AWS DataSync is a secure online data transfer service that simplifies, automates, and accelerates moving data between on-premises storage systems and AWS storage services, as well as between AWS storage services.

## Features

### Supported Location Types

- **Amazon S3** - Transfer data to/from S3 buckets
- **Amazon EFS** - Transfer data to/from Elastic File System
- **Amazon FSx for Windows File Server** - Transfer data to/from FSx Windows file systems
- **Amazon FSx for Lustre** - Transfer data to/from FSx Lustre file systems
- **Amazon FSx for NetApp ONTAP** - Transfer data to/from FSx ONTAP file systems with NFS/SMB protocols
- **Amazon FSx for OpenZFS** - Transfer data to/from FSx OpenZFS file systems
- **Network File System (NFS)** - Transfer data from on-premises NFS servers
- **Server Message Block (SMB)** - Transfer data from on-premises SMB file shares
- **Hadoop Distributed File System (HDFS)** - Transfer data from HDFS clusters
- **Object Storage** - Transfer data from object storage systems
- **Azure Blob Storage** - Transfer data from Azure Blob containers

### Task Management

- **DataSync Tasks** - Configure data transfer tasks between locations
- **Task Options** - Advanced settings for data transfer behavior
- **File Filtering** - Include/exclude filters for selective data transfer
- **Scheduled Execution** - Automatic task execution using CloudWatch Events
- **CloudWatch Logging** - Optional logging to CloudWatch Log Groups

## Usage

### Basic S3 to EFS Transfer

```hcl
module "datasync" {
  source = "./modules/Datasync"
  
  common = {
    global           = false
    tags             = {
      Environment = "production"
      Project     = "data-migration"
    }
    account_name     = "mycompany"
    region_prefix    = "us-east-1"
    account_name_abr = "mc"
  }
  
  datasync = {
    location_name = "s3-to-efs-sync"
    
    # S3 Source Location
    s3_location = {
      s3_bucket_arn          = "arn:aws:s3:::my-source-bucket"
      subdirectory           = "/data"
      bucket_access_role_arn = "arn:aws:iam::123456789012:role/DataSyncS3Role"
      s3_storage_class       = "STANDARD"
    }
    
    # EFS Destination Location
    efs_location = {
      name                = "target-efs"
      efs_file_system_arn = "arn:aws:elasticfilesystem:us-east-1:123456789012:file-system/fs-12345678"
      subdirectory        = "/backup"
      ec2_config = {
        security_group_arns = ["arn:aws:ec2:us-east-1:123456789012:security-group/sg-12345678"]
        subnet_arn          = "arn:aws:ec2:us-east-1:123456789012:subnet/subnet-12345678"
      }
      in_transit_encryption = "TLS1_2"
    }
    
    # DataSync Task Configuration
    task = {
      name                     = "s3-to-efs-migration"
      location_name            = "s3-to-efs-sync"
      source_location_arn      = module.datasync.s3_location_arn
      destination_location_arn = module.datasync.efs_location_arn
      cloudwatch_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/datasync"
      
      # Task Options
      options = {
        log_level      = "TRANSFER"
        overwrite_mode = "ALWAYS"
        verify_mode    = "POINT_IN_TIME_CONSISTENT"
        transfer_mode  = "CHANGED"
      }
      
      # Schedule (optional) - Run daily at 2 AM UTC
      schedule_expression = "cron(0 2 * * ? *)"
      
      # File Filters (optional)
      excludes = [
        {
          filter_type = "SIMPLE_PATTERN"
          value       = "*.tmp"
        }
      ]
    }
  }
}
```

### On-Premises NFS to S3 Transfer

```hcl
module "nfs_to_s3_datasync" {
  source = "./modules/Datasync"
  
  common = {
    global           = false
    tags             = local.common_tags
    account_name     = "mycompany"
    region_prefix    = "us-west-2"
  }
  
  datasync = {
    location_name = "nfs-to-s3-backup"
    
    # On-premises NFS Location
    nfs_location = {
      server_hostname = "nfs.example.com"
      subdirectory    = "/data/backups"
      on_prem_config = {
        agent_arns = ["arn:aws:datasync:us-west-2:123456789012:agent/agent-12345678"]
      }
      mount_options = {
        version = "AUTOMATIC"
      }
    }
    
    # S3 Destination Location
    s3_location = {
      s3_bucket_arn          = "arn:aws:s3:::backup-bucket"
      subdirectory           = "/nfs-backups"
      bucket_access_role_arn = "arn:aws:iam::123456789012:role/DataSyncS3Role"
      s3_storage_class       = "STANDARD_IA"
    }
    
    # Task with weekly schedule
    task = {
      name                     = "weekly-nfs-backup"
      location_name            = "nfs-to-s3-backup"
      source_location_arn      = module.nfs_to_s3_datasync.nfs_location_arn
      destination_location_arn = module.nfs_to_s3_datasync.s3_location_arn
      
      options = {
        bytes_per_second       = 104857600  # 100 MB/s
        preserve_deleted_files = "PRESERVE"
        verify_mode           = "ONLY_FILES_TRANSFERRED"
      }
      
      # Run every Sunday at 1 AM
      schedule_expression = "cron(0 1 ? * SUN *)"
    }
  }
}
```

### FSx Windows to Azure Blob Transfer

```hcl
module "fsx_to_azure_datasync" {
  source = "./modules/Datasync"
  
  common = {
    global        = false
    tags          = local.common_tags
    account_name  = "mycompany"
    region_prefix = "eu-west-1"
  }
  
  datasync = {
    location_name = "fsx-to-azure-migration"
    
    # FSx Windows Source Location
    fsx_windows_location = {
      fsx_filesystem_arn  = "arn:aws:fsx:eu-west-1:123456789012:file-system/fs-12345678"
      subdirectory        = "/shared/data"
      user                = "datasync-user"
      domain              = "example.com"
      password            = var.fsx_password
      security_group_arns = ["arn:aws:ec2:eu-west-1:123456789012:security-group/sg-12345678"]
    }
    
    # Azure Blob Destination Location
    azure_blob_location = {
      location_name       = "azure-target"
      agent_arns          = ["arn:aws:datasync:eu-west-1:123456789012:agent/agent-87654321"]
      container_url       = "https://mystorageaccount.blob.core.windows.net/backups"
      subdirectory        = "/fsx-data"
      authentication_type = "SAS"
      sas_configuration = {
        token = var.azure_sas_token
      }
      blob_type   = "BLOCK"
      access_tier = "HOT"
    }
  }
}
```

## Deploying with Terragrunt

Terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules. Here's how to deploy this DataSync module using Terragrunt:

### Basic Terragrunt Configuration

Create a `terragrunt.hcl` file in your environment-specific directory:

```hcl
# terragrunt.hcl
terraform {
  source = "git::https://github.com/KahBrightTech/Cognitech-terraform-iac-modules.git//terraform/modules/Datasync?ref=main"
}

# Include the root terragrunt configuration
include "root" {
  path = find_in_parent_folders()
}

# Include common variables
include "common" {
  path = find_in_parent_folders("common.hcl")
}

inputs = {
  datasync = {
    location_name = "s3-to-efs-backup"
    
    # S3 Source Location
    s3_location = {
      s3_bucket_arn          = "arn:aws:s3:::my-source-bucket"
      subdirectory           = "/data"
      bucket_access_role_arn = dependency.iam.outputs.datasync_s3_role_arn
      s3_storage_class       = "STANDARD"
    }
    
    # EFS Destination Location
    efs_location = {
      name                = "backup-efs"
      efs_file_system_arn = dependency.efs.outputs.efs_arn
      subdirectory        = "/backups"
      ec2_config = {
        security_group_arns = [dependency.security_groups.outputs.datasync_sg_arn]
        subnet_arn          = dependency.vpc.outputs.private_subnet_arns[0]
      }
      in_transit_encryption = "TLS1_2"
    }
    
    # DataSync Task
    task = {
      name                     = "daily-s3-efs-sync"
      location_name            = "s3-to-efs-backup"
      source_location_arn      = "" # Will be populated by module
      destination_location_arn = "" # Will be populated by module
      cloudwatch_log_group_arn = dependency.logs.outputs.datasync_log_group_arn
      
      options = {
        log_level      = "TRANSFER"
        overwrite_mode = "ALWAYS"
        verify_mode    = "POINT_IN_TIME_CONSISTENT"
        transfer_mode  = "CHANGED"
      }
      
      # Run daily at 2 AM UTC
      schedule_expression = "cron(0 2 * * ? *)"
    }
  }
}

# Dependencies
dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    private_subnet_arns = ["arn:aws:ec2:us-east-1:123456789012:subnet/subnet-12345678"]
  }
}

dependency "efs" {
  config_path = "../efs"
  mock_outputs = {
    efs_arn = "arn:aws:elasticfilesystem:us-east-1:123456789012:file-system/fs-12345678"
  }
}

dependency "iam" {
  config_path = "../iam"
  mock_outputs = {
    datasync_s3_role_arn = "arn:aws:iam::123456789012:role/DataSyncS3Role"
  }
}

dependency "security_groups" {
  config_path = "../security-groups"
  mock_outputs = {
    datasync_sg_arn = "arn:aws:ec2:us-east-1:123456789012:security-group/sg-12345678"
  }
}

dependency "logs" {
  config_path = "../cloudwatch-logs"
  mock_outputs = {
    datasync_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/datasync"
  }
}
```

### Directory Structure

Organize your Terragrunt configuration with a clear directory structure:

```
infrastructure/
├── terragrunt.hcl                 # Root terragrunt config
├── common.hcl                     # Common variables
├── environments/
│   ├── dev/
│   │   ├── us-east-1/
│   │   │   ├── vpc/
│   │   │   │   └── terragrunt.hcl
│   │   │   ├── efs/
│   │   │   │   └── terragrunt.hcl
│   │   │   ├── iam/
│   │   │   │   └── terragrunt.hcl
│   │   │   ├── security-groups/
│   │   │   │   └── terragrunt.hcl
│   │   │   ├── cloudwatch-logs/
│   │   │   │   └── terragrunt.hcl
│   │   │   └── datasync/
│   │   │       └── terragrunt.hcl
│   │   └── us-west-2/
│   │       └── datasync/
│   │           └── terragrunt.hcl
│   ├── staging/
│   └── prod/
```

### Common Configuration (common.hcl)

```hcl
# common.hcl
locals {
  # Common variables that can be used across all modules
  common_vars = {
    global           = false
    account_name     = "cognitech"
    account_name_abr = "ct"
    
    # Environment-specific region prefix
    region_prefix = get_env("AWS_DEFAULT_REGION", "us-east-1")
    
    # Common tags applied to all resources
    tags = {
      Environment   = path_relative_to_include()
      ManagedBy     = "Terragrunt"
      Project       = "DataSync"
      Repository    = "Cognitech-terraform-iac-modules"
      Owner         = "Platform-Team"
    }
  }
}

inputs = {
  common = local.common_vars
}
```

### Root Terragrunt Configuration (terragrunt.hcl)

```hcl
# Root terragrunt.hcl
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "cognitech-terraform-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "cognitech-terraform-locks"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "${get_env("AWS_DEFAULT_REGION", "us-east-1")}"
  
  default_tags {
    tags = {
      ManagedBy = "Terragrunt"
      Project   = "DataSync"
    }
  }
}
EOF
}
```

### Deployment Commands

Navigate to your specific environment directory and run:

```bash
# Plan the deployment
terragrunt plan

# Apply the configuration
terragrunt apply

# Destroy resources (when needed)
terragrunt destroy

# Apply all modules in the current directory tree
terragrunt run-all apply

# Plan all modules in the current directory tree
terragrunt run-all plan
```

### Advanced Terragrunt Features

#### 1. Using Dependencies with Outputs

```hcl
# In your datasync terragrunt.hcl
inputs = {
  datasync = {
    s3_location = {
      s3_bucket_arn = dependency.s3.outputs.bucket_arn
      # ... other config
    }
    efs_location = {
      efs_file_system_arn = dependency.efs.outputs.file_system_arn
      # ... other config
    }
  }
}
```

#### 2. Environment-Specific Variables

```hcl
# In environments/prod/datasync/terragrunt.hcl
locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

inputs = {
  datasync = {
    task = {
      options = {
        bytes_per_second = local.env_vars.locals.high_bandwidth_limit
      }
      schedule_expression = "cron(0 1 * * ? *)" # Prod runs at 1 AM
    }
  }
}
```

#### 3. Multiple DataSync Tasks

```hcl
# For multiple DataSync configurations, create separate directories:
# - datasync-backup/
# - datasync-archive/
# - datasync-replication/

# Each with their own terragrunt.hcl configurations
```

### Best Practices with Terragrunt

1. **State Management**: Use S3 backend with DynamoDB locking
2. **Module Versioning**: Pin module versions using Git tags
3. **Dependencies**: Use explicit dependencies between modules
4. **Environment Isolation**: Separate state files per environment
5. **Variable Management**: Use `common.hcl` for shared variables
6. **Mock Outputs**: Always provide mock outputs for dependencies

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| common | Common variables used by all resources | `object` | n/a | yes |
| datasync | DataSync configuration with all location types and task settings | `object` | `{}` | no |

### Common Variable Structure

```hcl
common = {
  global           = bool
  tags             = map(string)
  account_name     = string
  region_prefix    = string
  account_name_abr = optional(string)
}
```

### DataSync Variable Structure

The `datasync` variable is a complex object that supports all DataSync location types and task configuration. Each location type is optional, allowing you to configure only the locations you need.

#### Task Configuration

```hcl
task = {
  name                     = string
  location_name            = string
  source_location_arn      = string
  destination_location_arn = string
  cloudwatch_log_group_arn = optional(string)
  schedule_expression      = optional(string)  # CloudWatch Events schedule expression
  
  options = optional({
    atime                          = optional(string)
    bytes_per_second               = optional(number)
    gid                            = optional(string)
    log_level                      = optional(string)
    mtime                          = optional(string)
    overwrite_mode                 = optional(string)
    posix_permissions              = optional(string)
    preserve_deleted_files         = optional(string)
    preserve_devices               = optional(string)
    security_descriptor_copy_flags = optional(string)
    task_queueing                  = optional(string)
    transfer_mode                  = optional(string)
    uid                            = optional(string)
    verify_mode                    = optional(string)
  })
  
  excludes = optional(list(object({
    filter_type = string
    value       = string
  })))
  
  includes = optional(list(object({
    filter_type = string
    value       = string
  })))
}
```

#### Location Types

Each location type has its own configuration structure. Refer to the `variables.tf` file for complete details on each location type's required and optional parameters.

## Outputs

| Name | Description |
|------|-------------|
| s3_location_arn | ARN of the DataSync S3 location |
| efs_location_arn | ARN of the DataSync EFS location |
| fsx_windows_location_arn | ARN of the DataSync FSx Windows location |
| fsx_lustre_location_arn | ARN of the DataSync FSx Lustre location |
| fsx_ontap_location_arn | ARN of the DataSync FSx ONTAP location |
| fsx_openzfs_location_arn | ARN of the DataSync FSx OpenZFS location |
| nfs_location_arn | ARN of the DataSync NFS location |
| smb_location_arn | ARN of the DataSync SMB location |
| hdfs_location_arn | ARN of the DataSync HDFS location |
| object_storage_location_arn | ARN of the DataSync Object Storage location |
| azure_blob_location_arn | ARN of the DataSync Azure Blob location |
| datasync_task_arn | ARN of the DataSync task |
| datasync_task_status | Status of the DataSync task |
| datasync_schedule_rule_arn | ARN of the CloudWatch Event Rule for DataSync scheduling |
| datasync_events_role_arn | ARN of the IAM role used by CloudWatch Events for DataSync |
| all_location_arns | List of all created DataSync location ARNs |
| datasync_locations_count | Number of DataSync locations created |

## Important Considerations

### Security

1. **IAM Roles**: Ensure proper IAM roles are configured for DataSync to access source and destination locations
2. **Security Groups**: Configure security groups to allow DataSync traffic
3. **Encryption**: Enable encryption in transit and at rest where supported
4. **Credentials**: Store sensitive credentials (passwords, access keys) securely using AWS Secrets Manager or Parameter Store

### Performance

1. **Bandwidth Throttling**: Use `bytes_per_second` option to control bandwidth usage
2. **Network Configuration**: Ensure adequate network connectivity between source and destination
3. **VPC Endpoints**: Consider using VPC endpoints for AWS service communication

### Cost Optimization

1. **Storage Classes**: Choose appropriate S3 storage classes for cost optimization
2. **Transfer Scheduling**: Schedule transfers during off-peak hours
3. **Incremental Transfers**: Use `transfer_mode = "CHANGED"` for incremental transfers

### Monitoring

1. **CloudWatch Logs**: Enable logging for transfer monitoring and troubleshooting
2. **CloudWatch Metrics**: Monitor DataSync metrics for performance insights
3. **Task Execution History**: Review task execution history in the AWS Console

## Examples

See the usage examples above for common DataSync scenarios including:
- S3 to EFS transfers
- On-premises NFS to S3 backups
- FSx Windows to Azure Blob migrations

For more advanced configurations and additional location types, refer to the AWS DataSync documentation and the module's variable definitions.

## License

This module is released under the MIT License. See LICENSE file for details.