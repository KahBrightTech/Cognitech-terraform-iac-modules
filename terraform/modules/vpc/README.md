# VPC Module

This Terraform module creates a Virtual Private Cloud (VPC) with an Internet Gateway, providing the foundation for AWS networking infrastructure.

## Features

- **VPC Creation**: Creates a VPC with configurable CIDR block
- **Internet Gateway**: Automatically creates and attaches an Internet Gateway
- **DNS Support**: Enables DNS hostnames and resolution
- **Default Tenancy**: Configures default tenancy for cost optimization
- **Automatic Tagging**: Applies consistent naming and tagging conventions

## Prerequisites

- AWS provider configured with appropriate permissions
- IAM permissions for VPC and Internet Gateway creation

## Usage with Terragrunt

### Basic VPC Configuration

Create a `terragrunt.hcl` file in your formation directory:

```hcl
# terragrunt.hcl
terraform {
  source = "git::https://github.com/KahBrightTech/Cognitech-terraform-iac-modules.git//terraform/modules/vpc?ref=main"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  common = {
    global        = false
    tags          = {
      Environment = "production"
      Project     = "web-infrastructure"
      Owner       = "network-team"
    }
    account_name  = "production"
    region_prefix = "us-east-1"
  }
  
  vpc = {
    name       = "main"
    cidr_block = "10.0.0.0/16"
  }
}
```

### Development Environment VPC

```hcl
inputs = {
  common = {
    global        = false
    tags          = {
      Environment = "development"
      Project     = "dev-environment"
      Owner       = "development-team"
    }
    account_name  = "development"
    region_prefix = "us-west-2"
  }
  
  vpc = {
    name       = "dev-vpc"
    cidr_block = "172.16.0.0/16"
  }
}
```

### Multi-Environment Setup

```hcl
# Production VPC
inputs = {
  common = {
    global        = false
    tags          = {
      Environment = "production"
      CostCenter  = "infrastructure"
      Backup      = "required"
    }
    account_name  = "prod"
    region_prefix = "us-east-1"
  }
  
  vpc = {
    name       = "prod-vpc"
    cidr_block = "10.0.0.0/16"
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

### `vpc`

- **Description**: The VPC configuration
- **Type**: `object({...})`
- **Required**: Yes

Object structure:

- `name` (string): Name identifier for the VPC
- `cidr_block` (string): CIDR block for the VPC (e.g., "10.0.0.0/16")

## Outputs

### `vpc_id`

- **Description**: The ID of the created VPC
- **Type**: `string`

### `vpc_arn`

- **Description**: The ARN of the created VPC
- **Type**: `string`

### `vpc_cidr_block`

- **Description**: The CIDR block of the VPC
- **Type**: `string`

### `internet_gateway_id`

- **Description**: The ID of the Internet Gateway
- **Type**: `string`

### `vpc_default_security_group_id`

- **Description**: The ID of the default security group
- **Type**: `string`

### `vpc_default_route_table_id`

- **Description**: The ID of the default route table
- **Type**: `string`

## CIDR Block Planning

### Common CIDR Blocks

- **10.0.0.0/16**: 65,536 IP addresses (recommended for production)
- **172.16.0.0/16**: 65,536 IP addresses (good for development)
- **192.168.0.0/16**: 65,536 IP addresses (traditional private range)

### Subnet Planning Examples

For a 10.0.0.0/16 VPC:

- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
- **Private Subnets**: 10.0.10.0/24, 10.0.11.0/24, 10.0.12.0/24
- **Database Subnets**: 10.0.20.0/24, 10.0.21.0/24, 10.0.22.0/24

## Integration with Other Modules

### Subnets

After creating the VPC, use the subnet modules:

```hcl
# Public subnets
module "public_subnets" {
  source = "./modules/subnets/public_subnets"
  
  vpc_id = module.vpc.vpc_id
  # ... other configuration
}

# Private subnets
module "private_subnets" {
  source = "./modules/subnets/private_subnets"
  
  vpc_id = module.vpc.vpc_id
  # ... other configuration
}
```

### Security Groups

```hcl
module "security_groups" {
  source = "./modules/Security-group"
  
  vpc_id = module.vpc.vpc_id
  # ... other configuration
}
```

### Route Tables

```hcl
module "routes" {
  source = "./modules/Routes"
  
  vpc_id             = module.vpc.vpc_id
  internet_gateway_id = module.vpc.internet_gateway_id
  # ... other configuration
}
```

## Best Practices

1. **CIDR Planning**: Plan your CIDR blocks carefully to avoid conflicts
2. **DNS Settings**: Keep DNS hostnames and resolution enabled
3. **Tagging**: Use consistent tagging for resource management
4. **Multiple AZs**: Design for multiple availability zones
5. **Security**: Implement proper security groups and NACLs
6. **Monitoring**: Enable VPC Flow Logs for monitoring
7. **Cost Optimization**: Use appropriate instance tenancy

## Common Use Cases

- **Web Applications**: Foundation for web application infrastructure
- **Multi-Tier Applications**: Supporting web, application, and database tiers
- **Microservices**: Container orchestration platforms
- **Development Environments**: Isolated development networks
- **Hybrid Cloud**: On-premises connectivity with VPN or Direct Connect

## Networking Concepts

### VPC Features

- **Isolation**: Logically isolated network in the AWS cloud
- **Scalability**: Supports thousands of instances
- **Flexibility**: Multiple subnets across availability zones
- **Security**: Built-in security features and controls

### Internet Gateway

- **Purpose**: Allows communication between VPC and the internet
- **Scaling**: Horizontally scaled, redundant, and highly available
- **Routing**: Provides a target for internet-routable traffic

## Troubleshooting

### Common Issues

1. **CIDR Conflicts**: Ensure CIDR blocks don't overlap with existing networks
2. **DNS Resolution**: Verify DNS settings are enabled
3. **Internet Access**: Check Internet Gateway attachment
4. **Route Table**: Ensure proper routing configuration

### Debugging Steps

1. Verify VPC creation in AWS console
2. Check Internet Gateway attachment
3. Validate CIDR block configuration
4. Test DNS resolution settings

## Module Structure

```text
vpc/
├── main.tf       # Main resource definitions
├── variables.tf  # Input variable definitions
├── outputs.tf    # Output definitions
├── providers.tf  # Provider configurations
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
| aws_vpc.main | resource |
| aws_internet_gateway.main_igw | resource |

## VPC Limits

### Default Limits (per region)

- **VPCs**: 5 (can be increased)
- **Subnets**: 200 per VPC
- **Route Tables**: 200 per VPC
- **Security Groups**: 2,500 per VPC
- **Internet Gateways**: 5 per region

### CIDR Block Limits

- **Minimum**: /28 (16 IP addresses)
- **Maximum**: /16 (65,536 IP addresses)
- **Secondary CIDR**: Up to 4 additional CIDR blocks per VPC

## Next Steps

After creating the VPC, you'll typically want to:

1. Create subnets in multiple availability zones
2. Set up route tables for public and private subnets
3. Create security groups for different application tiers
4. Configure NAT gateways for private subnet internet access
5. Set up VPC endpoints for AWS services
6. Enable VPC Flow Logs for monitoring
