# Launch Template Module

This Terraform module creates an AWS Launch Template with pre-configured AMI selection, security settings, and instance configurations for use with Auto Scaling Groups, EC2 instances, and Spot Fleet requests.

## Features

- 🎯 **Smart AMI Selection**: Automatic AMI selection based on OS type and release date
- 🔒 **Security Integration**: Support for security groups and IAM instance profiles
- 💾 **Storage Configuration**: Configurable EBS block device mappings
- 🏷️ **Flexible Tagging**: Support for resource tagging and tag specifications
- 🔧 **User Data Support**: Custom user data script injection
- 🌐 **Network Configuration**: VPC security group and public IP configuration

## Supported AMI Types

The module includes pre-configured AMI mappings for:

- **AL2**: Amazon Linux 2 (amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2)
- **AL2023**: Amazon Linux 2023 (al2023-ami-*-kernel-6.1-x86_64)

## Usage

### Basic Example

```terraform
module "launch_template" {
  source = "./modules/Launch_template"
  
  common = {
    account_name  = "mycompany"
    region_prefix = "us-east-1"
    global        = false
    tags = {
      Project = "web-platform"
    }
  }
  
  launch_template = {
    name          = "web-server-template"
    instance_type = "t3.medium"
    key_name      = "my-key-pair"
    ami_config = {
      os_release_date  = "2023-12-01"
      os_base_packages = "AL2023"
    }
  }
}
```

### Advanced Example with Custom Configuration

```terraform
module "launch_template" {
  source = "./modules/Launch_template"
  
  common = {
    account_name     = "production"
    region_prefix    = "us-west-2"
    global           = false
    account_name_abr = "prod"
    tags = {
      Environment = "production"
      Team        = "platform"
    }
  }
  
  launch_template = {
    name                        = "api-server-template"
    instance_type               = "c5.xlarge"
    key_name                    = "prod-key"
    instance_profile            = "EC2-SSM-Role"
    associate_public_ip_address = false
    
    # AMI Configuration
    ami_config = {
      os_release_date  = "2023-12-01"
      os_base_packages = "AL2023"
    }
    
    # Or specify custom AMI
    # custom_ami = "ami-12345678"
    
    # VPC Security Groups
    vpc_security_group_ids = [
      "sg-web-servers",
      "sg-monitoring"
    ]
    
    # Custom User Data
    user_data = base64encode(<<-EOF
      #!/bin/bash
      yum update -y
      yum install -y docker
      systemctl start docker
      systemctl enable docker
      EOF
    )
    
    # Resource Tags
    tags = {
      "Application"   = "api-service"
      "Cost-Center"   = "engineering"
      "Backup"        = "required"
    }
  }
}
```

### Example with EBS Block Device Mapping

```terraform
module "launch_template" {
  source = "./modules/Launch_template"
  
  common = {
    account_name  = "mycompany"
    region_prefix = "us-east-1"
    global        = false
    tags = {}
  }
  
  launch_template = {
    name          = "storage-optimized-template"
    instance_type = "r5.large"
    key_name      = "my-key"
    
    ami_config = {
      os_release_date  = "2023-12-01"
      os_base_packages = "AL2023"
    }
    
    # Note: Block device mappings would need to be added to the module
    # This is a placeholder for future enhancement
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_launch_template.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_ami.launch_template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| common | Common variables used by all resources | `object({`<br>`global = bool`<br>`tags = map(string)`<br>`account_name = string`<br>`region_prefix = string`<br>`account_name_abr = optional(string)`<br>`})` | n/a | yes |
| launch_template | Launch Template configuration | `object({`<br>`name = string`<br>`instance_profile = optional(string)`<br>`custom_ami = optional(string)`<br>`ami_config = object({`<br>`os_release_date = optional(string)`<br>`os_base_packages = optional(string)`<br>`})`<br>`instance_type = optional(string)`<br>`key_name = optional(string)`<br>`associate_public_ip_address = optional(bool)`<br>`vpc_security_group_ids = optional(list(string))`<br>`tags = optional(map(string))`<br>`user_data = optional(string)`<br>`})` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| launch_template_id | The ID of the launch template |
| launch_template_arn | The ARN of the launch template |
| name | The name of the launch template |

## AMI Selection Logic

The module uses intelligent AMI selection based on the provided configuration:

### 1. Custom AMI
If `custom_ami` is specified, it takes precedence:
```terraform
launch_template = {
  custom_ami = "ami-12345678"  # Uses this specific AMI
}
```

### 2. Automatic AMI Selection
If `ami_config` is provided, the module selects the most recent AMI matching the criteria:

```terraform
launch_template = {
  ami_config = {
    os_base_packages = "AL2023"        # Amazon Linux 2023
    os_release_date  = "2023-12-01"    # Optional: filter by release date
  }
}
```

### Supported OS Types:
- **AL2**: Amazon Linux 2 (Long-term support)
- **AL2023**: Amazon Linux 2023 (Latest generation)

## Security Considerations

### IAM Instance Profile
Specify an IAM instance profile for EC2 permissions:
```terraform
launch_template = {
  instance_profile = "EC2-SSM-Role"  # For Systems Manager access
}
```

### Security Groups
Configure VPC security groups:
```terraform
launch_template = {
  vpc_security_group_ids = [
    "sg-web-tier",
    "sg-monitoring"
  ]
}
```

### Key Pairs
Specify EC2 Key Pair for SSH access:
```terraform
launch_template = {
  key_name = "my-production-key"
}
```

## Network Configuration

### Public IP Assignment
Control whether instances get public IP addresses:
```terraform
launch_template = {
  associate_public_ip_address = false  # Private instances only
}
```

## User Data

Inject custom initialization scripts:
```terraform
launch_template = {
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    # Your custom setup commands here
    EOF
  )
}
```

## Tagging

The module supports comprehensive tagging:

### Template-level Tags
Applied to the Launch Template resource itself:
```terraform
launch_template = {
  tags = {
    "Application"   = "web-service"
    "Environment"   = "production"
    "Team"          = "platform"
  }
}
```

### Instance Tags (Future Enhancement)
Tag specifications for instances launched from the template would be configured here.

## Best Practices

1. **AMI Selection**: Use `ami_config` for automatic AMI selection rather than hardcoding AMI IDs
2. **Security Groups**: Always specify appropriate security groups for your use case
3. **Instance Profiles**: Use IAM instance profiles instead of embedding credentials
4. **User Data**: Keep user data scripts minimal and use configuration management tools for complex setups
5. **Tagging**: Implement consistent tagging strategy for cost allocation and resource management

## Integration with Auto Scaling Groups

This module is designed to work seamlessly with the Auto Scaling Group module:

```terraform
# Launch Template
module "launch_template" {
  source = "./modules/Launch_template"
  # ... configuration
}

# Auto Scaling Group using the Launch Template
module "autoscaling_group" {
  source = "./modules/AutoSacling"
  
  launch_template = {
    # Configuration passed to launch template module
  }
  
  Autoscaling_group = {
    # ASG configuration
  }
}
```

## Troubleshooting

### Common Issues

1. **AMI Not Found**: Ensure the `os_base_packages` value matches supported types (AL2, AL2023)
2. **Permission Denied**: Verify IAM instance profile has necessary permissions
3. **Security Group**: Ensure security group IDs exist in the target VPC
4. **User Data**: Check that user data is properly base64 encoded

### Debugging

Enable detailed logging by checking:
- CloudTrail logs for API calls
- EC2 console for launch template details
- Instance logs for user data execution

## Deployment with Terragrunt

This module can be deployed using [Terragrunt](https://terragrunt.gruntwork.io/) for better infrastructure management and code organization.

### Directory Structure

```
infrastructure/
├── terragrunt.hcl                 # Root configuration
├── environments/
│   ├── dev/
│   │   ├── terragrunt.hcl        # Environment-specific config
│   │   └── launch-template/
│   │       └── terragrunt.hcl    # Component configuration
│   ├── staging/
│   │   ├── terragrunt.hcl
│   │   └── launch-template/
│   │       └── terragrunt.hcl
│   └── prod/
│       ├── terragrunt.hcl
│       └── launch-template/
│           └── terragrunt.hcl
```

### Root Terragrunt Configuration

**File**: `infrastructure/terragrunt.hcl`

```hcl
# Configure Terragrunt to automatically store tfstate files in S3
remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "your-terraform-state-bucket"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate an AWS provider block
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Terraform   = "true"
      Terragrunt  = "true"
      Environment = var.environment
      Project     = "cognitech-infrastructure"
    }
  }
}
EOF
}

# Generate common variables
generate "common_vars" {
  path      = "common-variables.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}
EOF
}
```

### Environment Configuration

**File**: `infrastructure/environments/prod/terragrunt.hcl`

```hcl
# Include the root terragrunt.hcl configuration
include "root" {
  path = find_in_parent_folders()
}

# Environment-specific inputs
inputs = {
  environment = "production"
  aws_region  = "us-east-1"
  
  # Common variables for all modules in this environment
  common = {
    account_name     = "cognitech-prod"
    region_prefix    = "us-east-1"
    global           = false
    account_name_abr = "ct-prod"
    tags = {
      Environment   = "production"
      ManagedBy     = "terragrunt"
      CostCenter    = "engineering"
      Project       = "web-platform"
    }
  }
}
```

### Launch Template Component Configuration

**File**: `infrastructure/environments/prod/launch-template/terragrunt.hcl`

```hcl
# Include the root terragrunt.hcl configuration
include "root" {
  path = find_in_parent_folders()
}

# Include environment-specific configuration
include "env" {
  path   = find_in_parent_folders("terragrunt.hcl")
  expose = true
}

# Specify the Terraform module source
terraform {
  source = "git::https://github.com/your-org/terraform-modules.git//terraform/modules/Launch_template?ref=v1.0.0"
}

# Module-specific inputs
inputs = merge(
  include.env.inputs,
  {
    # Launch Template Configuration
    launch_template = {
      name                        = "web-api-template-prod"
      instance_type               = "c5.xlarge"
      key_name                    = "production-keypair"
      instance_profile            = "WebAPI-EC2-SSM-Role"
      associate_public_ip_address = false
      
      # AMI Configuration - Use Amazon Linux 2023
      ami_config = {
        os_base_packages = "AL2023"
        os_release_date  = "2023-12-01"
      }
      
      # Alternative: Use custom AMI
      # custom_ami = "ami-0c02fb55956c7d316"
      
      # Security Configuration
      vpc_security_group_ids = [
        "sg-web-api-prod-001",
        "sg-monitoring-prod-001",
        "sg-logging-prod-001"
      ]
      
      # User Data Script
      user_data = base64encode(templatefile("${get_terragrunt_dir()}/scripts/user-data.sh", {
        environment     = "production"
        application     = "web-api"
        region         = "us-east-1"
        log_group      = "/aws/ec2/web-api/production"
        ssm_parameter  = "/web-api/prod/config"
      }))
      
      # Launch Template Tags
      tags = {
        Application      = "web-api"
        Team            = "backend-engineering"
        BusinessUnit    = "product"
        TemplateVersion = "v2.1.0"
        LastUpdated     = "2023-12-01"
        CostCenter      = "engineering"
      }
    }
  }
)

# Dependencies
dependencies {
  paths = [
    "../iam-roles",
    "../security-groups"
  ]
}
```

### User Data Script for Production

**File**: `infrastructure/environments/prod/launch-template/scripts/user-data.sh`

```bash
#!/bin/bash
# Launch Template User Data Script
# Environment: ${environment}
# Application: ${application}
# Region: ${region}

# Set up logging
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting user data script for ${application} in ${environment}"

# Update the system
dnf update -y

# Install necessary packages
dnf install -y \
    awscli \
    htop \
    jq \
    amazon-cloudwatch-agent \
    amazon-ssm-agent

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/messages",
                        "log_group_name": "${log_group}",
                        "log_stream_name": "{instance_id}/system",
                        "retention_in_days": 30
                    },
                    {
                        "file_path": "/var/log/user-data.log",
                        "log_group_name": "${log_group}",
                        "log_stream_name": "{instance_id}/user-data",
                        "retention_in_days": 30
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "Custom/EC2",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start and enable CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Enable and start SSM Agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Get application configuration from SSM Parameter Store
aws ssm get-parameter \
    --name "${ssm_parameter}" \
    --with-decryption \
    --region "${region}" \
    --output text \
    --query "Parameter.Value" > /opt/app-config.json 2>/dev/null || echo "{}" > /opt/app-config.json

# Set environment variables
echo "ENVIRONMENT=${environment}" >> /etc/environment
echo "APPLICATION=${application}" >> /etc/environment
echo "AWS_REGION=${region}" >> /etc/environment

# Create application directories
mkdir -p /opt/app/{bin,config,logs,data}
chmod 755 /opt/app
chmod 755 /opt/app/{bin,config,logs,data}

# Install Docker (if needed for containerized applications)
dnf install -y docker
systemctl enable docker
systemctl start docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# Set up log rotation
cat > /etc/logrotate.d/app-logs << 'EOF'
/opt/app/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 ec2-user ec2-user
    postrotate
        /bin/kill -HUP `cat /var/run/rsyslogd.pid 2>/dev/null` 2>/dev/null || true
    endscript
}
EOF

echo "User data script completed successfully"

# Signal completion (if using CloudFormation)
# /opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource AutoScalingGroup --region ${AWS::Region}
```

### Development Environment Configuration

**File**: `infrastructure/environments/dev/launch-template/terragrunt.hcl`

```hcl
# Include configurations
include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path   = find_in_parent_folders("terragrunt.hcl")
  expose = true
}

# Specify module source
terraform {
  source = "git::https://github.com/your-org/terraform-modules.git//terraform/modules/Launch_template?ref=v1.0.0"
}

# Development-specific inputs
inputs = merge(
  include.env.inputs,
  {
    launch_template = {
      name                        = "web-api-template-dev"
      instance_type               = "t3.medium"  # Smaller instance for dev
      key_name                    = "development-keypair"
      instance_profile            = "WebAPI-EC2-Dev-Role"
      associate_public_ip_address = true  # Public access for dev
      
      ami_config = {
        os_base_packages = "AL2023"
        os_release_date  = "2023-12-01"
      }
      
      vpc_security_group_ids = [
        "sg-web-api-dev-001"
      ]
      
      # Simplified user data for dev
      user_data = base64encode(<<-EOF
        #!/bin/bash
        dnf update -y
        dnf install -y docker htop jq
        systemctl start docker
        systemctl enable docker
        usermod -aG docker ec2-user
        echo "ENVIRONMENT=development" >> /etc/environment
        EOF
      )
      
      tags = {
        Application = "web-api"
        Team       = "backend-engineering"
        Purpose    = "development"
      }
    }
  }
)
```

### Deployment Commands

```bash
# Navigate to specific environment and component
cd infrastructure/environments/prod/launch-template

# Validate configuration
terragrunt validate

# Plan the deployment
terragrunt plan

# Apply the configuration
terragrunt apply

# Output values
terragrunt output

# Destroy if needed
terragrunt destroy
```

### Cross-Environment Operations

```bash
# From infrastructure root directory
cd infrastructure/

# Plan all launch templates across environments
find . -name "launch-template" -type d -exec sh -c 'cd "$1" && echo "=== Planning $1 ===" && terragrunt plan' _ {} \;

# Apply to all environments
find . -name "launch-template" -type d -exec sh -c 'cd "$1" && echo "=== Applying $1 ===" && terragrunt apply --auto-approve' _ {} \;
```

### Terragrunt Advantages for Launch Templates

1. **Environment Consistency**: Same template configuration across dev/staging/prod
2. **AMI Management**: Centralized AMI selection logic
3. **Security Policy**: Consistent security group and IAM role management
4. **User Data Templates**: Environment-specific user data injection
5. **Version Control**: Git-based module versioning and updates
6. **State Isolation**: Separate state files prevent cross-environment conflicts

### Best Practices

1. **AMI Versioning**: Use specific AMI release dates in production
2. **Secret Management**: Store sensitive data in AWS Systems Manager Parameter Store
3. **User Data Size**: Keep user data scripts under 16KB limit
4. **Testing**: Validate launch templates in development before production deployment
5. **Monitoring**: Include CloudWatch agent configuration in user data
6. **Security**: Use least-privilege IAM roles and security groups

## Contributing

When contributing to this module:

1. Test AMI selection logic thoroughly
2. Update documentation for any new AMI types
3. Ensure backward compatibility
4. Add appropriate validation for new variables

## License

This module is maintained by the DevOps team at Cognitech.
