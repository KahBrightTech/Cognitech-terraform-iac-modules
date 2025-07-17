# Acquire State Module

This Terraform module acquires remote state from multiple Terraform state backends stored in S3. It's useful for accessing outputs from other Terraform configurations in a centralized way.

## Features

- Retrieves remote state from multiple S3 backends
- Supports DynamoDB state locking
- Provides centralized access to outputs from other Terraform configurations
- Encrypts state data in transit

## Prerequisites

- AWS S3 buckets containing Terraform state files
- DynamoDB tables for state locking (if used)
- Appropriate IAM permissions to read from S3 and DynamoDB

## Usage with Terragrunt

### Basic Configuration

Create a `terragrunt.hcl` file in your formation directory:

```hcl
# terragrunt.hcl
terraform {
  source = "git::https://github.com/KahBrightTech/Cognitech-terraform-iac-modules.git//terraform/modules/acquire-state?ref=main"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  tf_remote_states = [
    {
      name            = "vpc"
      bucket_name     = "my-terraform-state-bucket"
      bucket_key      = "vpc/terraform.tfstate"
      lock_table_name = "terraform-state-lock"
    },
    {
      name            = "security-groups"
      bucket_name     = "my-terraform-state-bucket"
      bucket_key      = "security-groups/terraform.tfstate"
      lock_table_name = "terraform-state-lock"
    }
  ]
}
```

### Multiple Remote States

```hcl
inputs = {
  tf_remote_states = [
    {
      name            = "networking"
      bucket_name     = "prod-terraform-state"
      bucket_key      = "networking/terraform.tfstate"
      lock_table_name = "terraform-lock-table"
    },
    {
      name            = "database"
      bucket_name     = "prod-terraform-state"
      bucket_key      = "database/terraform.tfstate"
      lock_table_name = "terraform-lock-table"
    },
    {
      name            = "compute"
      bucket_name     = "prod-terraform-state"
      bucket_key      = "compute/terraform.tfstate"
      lock_table_name = "terraform-lock-table"
    }
  ]
}
```

## Input Variables

### `tf_remote_states`

- **Description**: List of remote states to acquire
- **Type**: `list(object({...}))`
- **Required**: Yes

Object structure:

- `name` (string): Name identifier for the remote state
- `bucket_name` (string): S3 bucket name containing the state file
- `bucket_key` (string): S3 object key path to the state file
- `lock_table_name` (string): DynamoDB table name for state locking

## Outputs

### `remote_tfstates`

- **Description**: Remote state backend configuration data
- **Type**: `map(object)`
- **Sensitive**: Yes

## Usage Example

After applying this module, you can access remote state outputs in other configurations:

```hcl
# In another module
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state-bucket"
    key    = "vpc/terraform.tfstate"
    region = "us-east-1"
  }
}

# Access VPC ID from remote state
resource "aws_security_group" "example" {
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  # ... rest of configuration
}
```

## Best Practices

1. **State File Organization**: Organize your state files in a logical directory structure within S3
2. **Naming Convention**: Use descriptive names for remote state references
3. **Security**: Ensure proper IAM permissions and encryption for state files
4. **Locking**: Always use DynamoDB for state locking in production environments
5. **Version Control**: Tag your state bucket and enable versioning

## Common Issues

- **Access Denied**: Ensure the executing role has read permissions to the S3 bucket and DynamoDB table
- **State Not Found**: Verify the bucket name and key path are correct
- **Lock Timeout**: Check if the DynamoDB table exists and is accessible

## Module Structure

```text
acquire-state/
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
| terraform_remote_state.states | data source |
