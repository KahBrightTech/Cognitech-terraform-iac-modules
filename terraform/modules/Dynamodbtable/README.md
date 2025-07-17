# DynamoDB Table Module

This Terraform module creates a DynamoDB table primarily designed for Terraform state locking, but can be used for general DynamoDB table creation with configurable attributes and billing modes.

## Features

- Creates DynamoDB tables with configurable attributes
- Supports both PAY_PER_REQUEST and PROVISIONED billing modes
- Automatic tagging with common naming conventions
- Designed for Terraform state locking but flexible for other use cases

## Prerequisites

- AWS provider configured with appropriate permissions
- IAM permissions for DynamoDB table creation and management

## Usage with Terragrunt

### Basic Configuration for State Locking

Create a `terragrunt.hcl` file in your formation directory:

```hcl
# terragrunt.hcl
terraform {
  source = "git::https://github.com/KahBrightTech/Cognitech-terraform-iac-modules.git//terraform/modules/Dynamodbtable?ref=main"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  common = {
    global        = false
    tags          = {
      Environment = "production"
      Project     = "terraform-state"
      Owner       = "infrastructure-team"
    }
    account_name  = "production"
    region_prefix = "us-east-1"
  }
  
  state_lock = {
    table_name = "terraform-state-lock"
    hash_key   = "LockID"
    attributes = [
      {
        name = "LockID"
        type = "S"
      }
    ]
    billing_mode = "PAY_PER_REQUEST"
  }
}
```

### Custom DynamoDB Table Configuration

```hcl
inputs = {
  common = {
    global        = false
    tags          = {
      Environment = "production"
      Application = "my-app"
    }
    account_name  = "production"
    region_prefix = "us-east-1"
  }
  
  state_lock = {
    table_name = "my-custom-table"
    hash_key   = "id"
    attributes = [
      {
        name = "id"
        type = "S"
      },
      {
        name = "sort_key"
        type = "S"
      }
    ]
    billing_mode = "PROVISIONED"
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

### `state_lock`

- **Description**: DynamoDB Table configuration for Terraform State Locking
- **Type**: `object({...})`
- **Required**: Yes

Object structure:

- `table_name` (string): Name of the DynamoDB table
- `hash_key` (string): Hash key for the table
- `attributes` (list(object)): List of table attributes
  - `name` (string): Attribute name
  - `type` (string): Attribute type (S, N, B)
- `billing_mode` (string, optional): Billing mode (default: "PAY_PER_REQUEST")

## Outputs

### `dynamodb_table`

- **Description**: The DynamoDB table resource
- **Type**: `object`

### `table_name`

- **Description**: The name of the created DynamoDB table
- **Type**: `string`

### `table_arn`

- **Description**: The ARN of the created DynamoDB table
- **Type**: `string`

## Usage Example

After applying this module, you can reference the table in your Terraform backend configuration:

```hcl
# terraform backend configuration
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

## Best Practices

1. **State Locking**: Always use DynamoDB for state locking in production environments
2. **Billing Mode**: Use PAY_PER_REQUEST for most use cases unless you have predictable traffic
3. **Naming**: Use consistent naming conventions for your tables
4. **Attributes**: Only define attributes that are used as keys
5. **Encryption**: Consider enabling encryption at rest for sensitive data

## Common Use Cases

- **Terraform State Locking**: Primary use case for preventing concurrent state modifications
- **Application Data**: General purpose NoSQL database tables
- **Session Storage**: Storing user session data
- **Configuration Management**: Storing application configuration

## Module Structure

```text
Dynamodbtable/
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
| aws_region.current | data source |
| aws_dynamodb_table.terraform_locks | resource |

## Attribute Types

DynamoDB supports the following attribute types:

- **S**: String
- **N**: Number
- **B**: Binary

## Billing Modes

- **PAY_PER_REQUEST**: Pay only for what you use (recommended for most cases)
- **PROVISIONED**: Pre-provision read and write capacity units
