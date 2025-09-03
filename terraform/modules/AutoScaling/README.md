# Auto Scaling Group (ASG) Module

This Terraform module creates an AWS Auto Scaling Group with configurable Launch Templates, dynamic tagging, and flexible timeout settings.

## Features

- 🚀 **Auto Scaling Group**: Creates AWS Auto Scaling Group with customizable capacity settings
- 🔧 **Launch Template Integration**: Automatically integrates with Launch Template module
- 🏷️ **Dynamic Tagging**: Supports both map-based and list-based tagging with propagation control
- ⏱️ **Configurable Timeouts**: Optional timeout configuration for delete operations
- 🎯 **Health Checks**: Configurable health check settings (ELB or EC2)

## Usage

### Basic Example

```terraform
module "autoscaling_group" {
  source = "./modules/AutoSacling"
  
  common = {
    account_name     = "mycompany"
    region_prefix    = "us-east-1"
    tags = {
      Project = "web-platform"
    }
  }
  
  Autoscaling_group = {
    name                      = "web-servers"
    min_size                  = 2
    max_size                  = 10
    desired_capacity          = 4
    health_check_type         = "ELB"
    health_check_grace_period = 300
    force_delete              = true
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

### Advanced Example with Multiple Tagging Options

```terraform
module "autoscaling_group" {
  source = "./modules/AutoSacling"
  
  common = {
    account_name     = "production"
    region_prefix    = "us-west-2"
    tags = {
      Environment = "prod"
    }
  }
  
  Autoscaling_group = {
    name                      = "api-servers"
    min_size                  = 3
    max_size                  = 15
    desired_capacity          = 6
    health_check_type         = "ELB"
    health_check_grace_period = 300
    force_delete              = false
    
    # Simple tags (all propagate to instances)
    tags = {
      "Application"   = "api-service"
      "Team"          = "backend"
      "Cost-Center"   = "engineering"
      "Environment"   = "production"
    }
    
    # Advanced tags with custom propagation
    additional_tags = [
      {
        key                 = "Auto-Scaling"
        value               = "enabled"
        propagate_at_launch = false  # ASG only
      },
      {
        key                 = "Monitoring"
        value               = "cloudwatch"
        propagate_at_launch = false  # ASG only
      },
      {
        key                 = "Backup"
        value               = "daily"
        propagate_at_launch = true   # ASG + instances
      }
    ]
    
    # Custom timeout for delete operations
    timeouts = {
      delete = "15m"
    }
  }
  
  launch_template = {
    name                        = "api-server-template"
    instance_type               = "c5.xlarge"
    key_name                    = "prod-key"
    associate_public_ip_address = false
    ami_config = {
      os_release_date  = "2023-12-01"
      os_base_packages = "AL2023"
    }
    vpc_security_group_ids = ["sg-12345678"]
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
| [aws_autoscaling_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| common | Common variables used by all resources | `object({`<br>`global = bool`<br>`tags = map(string)`<br>`account_name = string`<br>`region_prefix = string`<br>`account_name_abr = optional(string)`<br>`})` | n/a | yes |
| Autoscaling_group | Auto Scaling configuration | `object({`<br>`name = optional(string)`<br>`min_size = optional(number)`<br>`max_size = optional(number)`<br>`health_check_type = optional(string)`<br>`health_check_grace_period = optional(number)`<br>`force_delete = optional(bool)`<br>`desired_capacity = optional(number)`<br>`subnet_ids = optional(list(string))`<br>`timeouts = optional(object({`<br>`delete = optional(string)`<br>`}))`<br>`tags = optional(map(string))`<br>`additional_tags = optional(list(object({`<br>`key = string`<br>`value = string`<br>`propagate_at_launch = optional(bool, true)`<br>`})))`<br>`})` | `null` | no |
| launch_template | Launch Template configuration | See Launch Template module documentation | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| name | The name of the Auto Scaling group |
| arn | The ARN of the Auto Scaling group |
| id | The ID of the Auto Scaling group |
| subnet_ids | The subnet IDs associated with the Auto Scaling group |

## Tagging

This module supports two types of tagging:

### 1. Simple Tags (Map of Strings)
- All tags automatically propagate to launched instances
- Clean and simple syntax

```terraform
tags = {
  "Environment"   = "production"
  "Application"   = "web-app"
  "Team"          = "platform"
}
```

### 2. Advanced Tags (List of Objects)
- Fine-grained control over tag propagation
- Can specify whether each tag propagates to instances

```terraform
additional_tags = [
  {
    key                 = "Environment"
    value               = "production"
    propagate_at_launch = true   # Tag both ASG and instances
  },
  {
    key                 = "Auto-Scaling"
    value               = "enabled"
    propagate_at_launch = false  # Tag only ASG
  }
]
```

## Health Checks

The module supports two types of health checks:

- **ELB**: Uses load balancer health checks (recommended when using with ALB/NLB)
- **EC2**: Uses EC2 instance status checks

## Timeouts

Configure custom timeout for delete operations:

```terraform
timeouts = {
  delete = "15m"  # Wait up to 15 minutes for deletion
}
```

## Notes

- The module automatically creates a standardized naming convention: `{account_name}-{region_prefix}-{name}-asg`
- Launch Template integration is handled automatically through the submodule
- VPC zone identifiers are currently hardcoded and should be updated for production use
- Health check grace period default is typically 300 seconds (5 minutes)

## Deployment with Terragrunt

This module can be easily deployed using [Terragrunt](https://terragrunt.gruntwork.io/) for better code organization and DRY principles.

### Directory Structure

```
infrastructure/
├── terragrunt.hcl                 # Root configuration
├── environments/
│   ├── dev/
│   │   ├── terragrunt.hcl        # Environment-specific config
│   │   └── auto-scaling/
│   │       └── terragrunt.hcl    # Component configuration
│   ├── staging/
│   │   ├── terragrunt.hcl
│   │   └── auto-scaling/
│   │       └── terragrunt.hcl
│   └── prod/
│       ├── terragrunt.hcl
│       └── auto-scaling/
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
  
  # Common variables
  common = {
    account_name     = "cognitech-prod"
    region_prefix    = "us-east-1"
    global           = false
    account_name_abr = "ct-prod"
    tags = {
      Environment   = "production"
      ManagedBy     = "terragrunt"
      CostCenter    = "engineering"
    }
  }
}
```

### Auto Scaling Group Component Configuration

**File**: `infrastructure/environments/prod/auto-scaling/terragrunt.hcl`

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
  source = "git::https://github.com/your-org/terraform-modules.git//terraform/modules/AutoSacling?ref=v1.0.0"
}

# Module-specific inputs
inputs = merge(
  include.env.inputs,
  {
    # Auto Scaling Group Configuration
    Autoscaling_group = {
      name                      = "web-api-servers"
      min_size                  = 3
      max_size                  = 15
      desired_capacity          = 6
      health_check_type         = "ELB"
      health_check_grace_period = 300
      force_delete              = false
      
      # Production tags
      tags = {
        Application     = "web-api"
        Team           = "backend-team"
        BusinessUnit   = "product"
        BackupSchedule = "daily"
      }
      
      # Advanced tags with custom propagation
      additional_tags = [
        {
          key                 = "AutoScaling"
          value               = "enabled"
          propagate_at_launch = false
        },
        {
          key                 = "MonitoringLevel"
          value               = "enhanced"
          propagate_at_launch = false
        },
        {
          key                 = "ComplianceScope"
          value               = "pci-dss"
          propagate_at_launch = true
        }
      ]
      
      # Custom timeout for production
      timeouts = {
        delete = "20m"
      }
    }
    
    # Launch Template Configuration
    launch_template = {
      name                        = "web-api-template-prod"
      instance_type               = "c5.xlarge"
      key_name                    = "production-key"
      instance_profile            = "WebAPI-EC2-Role"
      associate_public_ip_address = false
      
      ami_config = {
        os_base_packages = "AL2023"
        os_release_date  = "2023-12-01"
      }
      
      vpc_security_group_ids = [
        "sg-web-api-prod",
        "sg-monitoring-prod"
      ]
      
      user_data = base64encode(templatefile("${get_terragrunt_dir()}/user-data.sh", {
        environment = "production"
        app_name    = "web-api"
      }))
      
      tags = {
        TemplateVersion = "v2.1.0"
        LastUpdated     = "2023-12-01"
      }
    }
  }
)

# Dependencies (if any)
dependencies {
  paths = [
    "../vpc",
    "../security-groups",
    "../iam-roles"
  ]
}
```

### User Data Script

**File**: `infrastructure/environments/prod/auto-scaling/user-data.sh`

```bash
#!/bin/bash
# User data script for ${app_name} in ${environment}

# Update system
yum update -y

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

# Configure application
echo "Environment: ${environment}" > /opt/app-config
echo "Application: ${app_name}" >> /opt/app-config

# Start services
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Signal completion
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource AutoScalingGroup --region ${AWS::Region}
```

### Deployment Commands

```bash
# Navigate to the environment directory
cd infrastructure/environments/prod/auto-scaling

# Plan the deployment
terragrunt plan

# Apply the configuration
terragrunt apply

# Destroy resources (if needed)
terragrunt destroy

# Plan all components in the environment
cd ../
terragrunt run-all plan

# Apply all components in the environment
terragrunt run-all apply
```

### Multi-Environment Deployment

Deploy across multiple environments:

```bash
# From the infrastructure root
cd infrastructure/

# Plan all environments
terragrunt run-all plan

# Apply to specific environment
cd environments/staging
terragrunt run-all apply

# Apply to production with confirmation
cd ../prod
terragrunt run-all apply --terragrunt-non-interactive=false
```

### Terragrunt Benefits

1. **DRY Configuration**: Shared configurations across environments
2. **Remote State Management**: Automatic S3 backend configuration
3. **Dependency Management**: Proper ordering of resource creation
4. **Environment Isolation**: Clear separation between dev/staging/prod
5. **Provider Generation**: Consistent AWS provider configuration
6. **Hooks Support**: Pre/post deployment actions

### Best Practices with Terragrunt

1. **Version Pinning**: Always specify module versions in source URLs
2. **State Isolation**: Use separate state files per component
3. **Dependency Declaration**: Explicitly declare inter-component dependencies
4. **Environment Variables**: Use `.terragrunt-version` files
5. **Validation**: Implement `terragrunt hclfmt` in CI/CD pipelines

## Contributing

When contributing to this module, please ensure:

1. All variables have proper descriptions
2. Examples are tested and working
3. README is updated with any new features
4. Terraform formatting is applied (`terraform fmt`)

## License

This module is maintained by the DevOps team at Cognitech.
