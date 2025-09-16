# EC2 Instance Module

This Terraform module creates AWS EC2 instances with comprehensive configuration options including AMI selection, EBS volumes, user data, and automatic tagging for backup and scheduling.

## Features

- **Multi-OS Support**: Supports Amazon Linux 2, AL2023, RHEL 9, RHEL 10, Windows Server 2019/2022/2025, and Ubuntu
- **Flexible AMI Selection**: Automatic AMI selection based on OS type or custom AMI override
- **EBS Volume Management**: Configurable root and additional EBS volumes with encryption support
- **User Data Integration**: Includes pre-configured user data scripts for different operating systems
- **Backup Integration**: Automatic tagging for AWS Backup integration
- **Scheduling Support**: Instance scheduling tags for automated start/stop
- **Security Group Integration**: Multiple security group attachment support

## Prerequisites

- AWS provider configured with appropriate permissions
- IAM instance profile for EC2 instances
- EC2 key pair for SSH/RDP access
- VPC and subnets configured
- Security groups configured

## Usage with Terragrunt

### Basic Linux Instance

Create a `terragrunt.hcl` file in your formation directory:

```hcl
# terragrunt.hcl
terraform {
  source = "git::https://github.com/KahBrightTech/Cognitech-terraform-iac-modules.git//terraform/modules/EC2-instance?ref=main"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  common = {
    global        = false
    tags          = {
      Environment = "production"
      Project     = "web-servers"
      Owner       = "infrastructure-team"
    }
    account_name  = "production"
    region_prefix = "us-east-1"
  }
  
  ec2 = {
    name          = "web-server-01"
    instance_type = "t3.medium"
    ami_config = {
      os_release_date  = "AL2023"
      os_base_packages = null
    }
    associate_public_ip_address = false
    iam_instance_profile        = "EC2-Default-Profile"
    key_name                    = "my-key-pair"
    subnet_id                   = "subnet-12345678"
    security_group_ids          = ["sg-12345678"]
    
    ebs_root_volume = {
      volume_size           = 30
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }
}
```

### Windows Instance with Additional Volume

```hcl
inputs = {
  common = {
    global        = false
    tags          = {
      Environment = "production"
      Project     = "database-servers"
    }
    account_name  = "production"
    region_prefix = "us-east-1"
  }
  
  ec2 = {
    name          = "db-server-01"
    instance_type = "m5.large"
    ami_config = {
      os_release_date  = "W22"
      os_base_packages = "BASE"
    }
    associate_public_ip_address = false
    iam_instance_profile        = "EC2-Database-Profile"
    key_name                    = "my-key-pair"
    subnet_id                   = "subnet-87654321"
    security_group_ids          = ["sg-87654321"]
    
    ebs_root_volume = {
      volume_size           = 50
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
    
    ebs_device_volume = {
      name                  = "data"
      volume_size           = 100
      volume_type           = "gp3"
      delete_on_termination = false
      encrypted             = true
    }
    
    Schedule_name     = "business-hours"
    backup_plan_name  = "daily-backup"
    
    custom_tags = {
      Database = "SQL-Server"
      Role     = "Primary"
    }
  }
}
```

### Custom AMI Configuration

```hcl
inputs = {
  ec2 = {
    name          = "custom-app-server"
    instance_type = "t3.large"
    custom_ami    = "ami-0123456789abcdef0"
    ami_config = {
      os_release_date  = "AL2023"  # Still needed for user data
      os_base_packages = null
    }
    # ... rest of configuration
  }
}
```

## Input Variables

### `common`

- **Description**: Common variables used by all resources
- **Type**: `object({...})`
- **Required**: Yes

Object structure:

- `global` (bool): Whether this is a global resource
- `tags` (map(string)): Tags to apply to all resources
- `account_name` (string): Name of the AWS account
- `region_prefix` (string): AWS region prefix
- `account_name_abr` (string, optional): Abbreviated account name

### `ec2`

- **Description**: EC2 Instance configuration
- **Type**: `object({...})`
- **Required**: Yes

Object structure:

- `name` (string): Instance name identifier
- `name_override` (string, optional): Override the auto-generated instance name
- `custom_ami` (string, optional): Custom AMI ID to use instead of auto-selection
- `ami_config` (object): AMI configuration for auto-selection
  - `os_release_date` (string, optional): OS release (AL2, AL2023, RHEL9, RHEL10, W19, W22, W25, UBUNTU20)
  - `os_base_packages` (string, optional): Base package set for Windows (BASE, SQLE19, SQLE22)
- `associate_public_ip_address` (bool, optional): Whether to associate public IP (default: false)
- `instance_type` (string): EC2 instance type
- `iam_instance_profile` (string): IAM instance profile name
- `key_name` (string): EC2 key pair name
- `custom_tags` (map(string), optional): Additional custom tags
- `ebs_root_volume` (object, optional): Root volume configuration
  - `volume_size` (number): Volume size in GB
  - `volume_type` (string, optional): Volume type (default: "gp3")
  - `delete_on_termination` (bool, optional): Delete on termination (default: true)
  - `encrypted` (bool, optional): Enable encryption (default: false)
  - `kms_key_id` (string, optional): KMS key ID for encryption
- `ebs_device_volume` (object, optional): Additional EBS volume configuration
  - `name` (string): Device name identifier
  - `volume_size` (number): Volume size in GB
  - `volume_type` (string, optional): Volume type (default: "gp3")
  - `delete_on_termination` (bool, optional): Delete on termination (default: true)
  - `encrypted` (bool, optional): Enable encryption (default: false)
  - `kms_key_id` (string, optional): KMS key ID for encryption
- `subnet_id` (string): Subnet ID for instance placement
- `Schedule_name` (string, optional): Schedule tag for instance automation
- `backup_plan_name` (string, optional): Backup plan tag for AWS Backup
- `security_group_ids` (list(string)): List of security group IDs

## Outputs

### `instance_id`

- **Description**: The ID of the EC2 instance
- **Type**: `string`

### `instance_arn`

- **Description**: The ARN of the EC2 instance
- **Type**: `string`

### `private_ip`

- **Description**: The private IP address of the instance
- **Type**: `string`

### `public_ip`

- **Description**: The public IP address of the instance (if applicable)
- **Type**: `string`

## Supported Operating Systems

### Linux

- **AL2**: Amazon Linux 2
- **AL2023**: Amazon Linux 2023
- **RHEL9**: Red Hat Enterprise Linux 9
- **RHEL10**: Red Hat Enterprise Linux 10
- **UBUNTU20**: Ubuntu 20.04 LTS

### Windows

- **W19**: Windows Server 2019
  - `BASE`: Base installation
  - `SQLE19`: SQL Server 2019 Enterprise
- **W22**: Windows Server 2022
  - `BASE`: Base installation
  - `SQLE22`: SQL Server 2022 Enterprise
- **W25**: Windows Server 2025
  - `BASE`: Base installation

## User Data Scripts

The module includes pre-configured user data scripts for each supported OS:

- `al2.sh`: Amazon Linux 2 initialization
- `al2023.sh`: Amazon Linux 2023 initialization
- `rhel.sh`: RHEL initialization
- `w19.ps1`: Windows Server 2019 initialization

## Best Practices

1. **Security**: Always use security groups to restrict access
2. **IAM**: Use least-privilege IAM instance profiles
3. **Encryption**: Enable EBS encryption for sensitive workloads
4. **Backup**: Configure backup plans for production instances
5. **Monitoring**: Use CloudWatch monitoring and logging
6. **Patching**: Implement automated patching strategies
7. **Tagging**: Use consistent tagging for resource management

## Common Use Cases

- **Web Servers**: Frontend and backend application servers
- **Database Servers**: Database instances with additional storage
- **Development Environments**: Development and testing instances
- **Bastion Hosts**: Secure access points for private networks
- **Application Servers**: Custom application hosting

## Module Structure

```text
EC2-instance/
├── main.tf       # Main resource definitions
├── variables.tf  # Input variable definitions
├── outputs.tf    # Output definitions
├── providers.tf  # Provider configurations
├── user_data/    # User data scripts
│   ├── al2.sh
│   ├── al2023.sh
│   ├── rhel.sh
│   └── w19.ps1
└── README.md     # This file
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Resources

| Name | Type |
|------|------|
| aws_caller_identity.current | data source |
| aws_region.current | data source |
| aws_iam_roles.admin_role | data source |
| aws_iam_roles.network_role | data source |
| aws_ami.ec2_instance | data source |
| aws_instance.ec2_instance | resource |
| aws_ebs_volume.device_volume | resource |
| aws_volume_attachment.device_attachment | resource |

## Troubleshooting

### Common Issues

1. **AMI Not Found**: Ensure the specified OS release date is supported
2. **Instance Launch Failure**: Check security group rules and subnet configuration
3. **Volume Attachment Issues**: Verify device names and availability zones
4. **User Data Execution**: Check CloudWatch logs for user data script execution

### Debugging

- Check EC2 instance system logs in the AWS console
- Review CloudWatch logs for user data execution
- Verify security group rules allow necessary traffic
- Ensure IAM instance profile has required permissions
