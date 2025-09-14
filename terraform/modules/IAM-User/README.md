# IAM User Module

This Terraform module creates an IAM user with optional access keys that are securely stored in AWS Secrets Manager.

## Features

- Creates IAM user with configurable permissions
- Generates access keys using external Python script
- Stores access keys securely in AWS Secrets Manager
- Supports IAM groups and policy attachments
- Configurable secrets recovery window

## Usage

```hcl
module "iam_user" {
  source = "./modules/IAM-User"

  common = {
    account_name  = "my-account"
    region_prefix = "us-east-1"
    global        = false
    tags = {
      Environment = "production"
      Team        = "platform"
    }
  }

  iam_user = {
    name                = "service-user"
    notifications_email = "admin@example.com"
    create_access_key   = true
    groups              = ["developers", "read-only"]
    
    secrets_manager = {
      recovery_window_in_days = 30
      description            = "Credentials for service user"
    }
    
    policy = {
      name        = "service-policy"
      description = "Policy for service user"
      policy      = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = ["s3:GetObject"]
            Resource = "*"
          }
        ]
      })
    }
    
    group_policies = [
      {
        group_name  = "developers"
        policy_name = "dev-s3-access"
        description = "S3 access for developers"
        policy = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action = ["s3:*"]
              Resource = ["arn:aws:s3:::dev-bucket/*"]
            }
          ]
        })
      },
      {
        group_name  = "read-only"
        policy_name = "readonly-access"
        description = "Read-only access policy"
        policy = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Effect = "Allow"
              Action = ["s3:GetObject", "s3:ListBucket"]
              Resource = "*"
            }
          ]
        })
      }
    ]
  }
  }
}
```

## Requirements

- Python 3.x for the external access key creation script
- AWS CLI configured with appropriate permissions
- Terraform >= 0.14

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| common | Common variables used by all resources | `object` | n/a | yes |
| iam_user | IAM User configuration | `object` | `null` | no |

### IAM User Object

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | IAM user name | `string` | n/a | yes |
| notifications_email | Email for notifications | `string` | n/a | yes |
| create_access_key | Whether to create access keys | `bool` | `true` | no |
| secrets_manager | Secrets Manager configuration | `object` | `{}` | no |
| path | IAM user path | `string` | `null` | no |
| permissions_boundary | Permissions boundary ARN | `string` | `null` | no |
| force_destroy | Allow force destruction | `bool` | `false` | no |
| groups | List of IAM groups | `list(string)` | `null` | no |
| policy | IAM policy configuration | `object` | `null` | no |
| group_policies | List of policies to attach to groups | `list(object)` | `[]` | no |

### Secrets Manager Object

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| recovery_window_in_days | Secret recovery window | `number` | `30` | no |
| description | Secret description | `string` | `null` | no |

### Group Policies Object

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| group_name | Name of the IAM group to attach policy to | `string` | n/a | yes |
| policy_name | Name for the policy | `string` | n/a | yes |
| description | Policy description | `string` | `null` | no |
| policy | Policy document in JSON format | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| iam_user_arn | The ARN of the IAM User |
| iam_user_name | The name of the IAM User |
| secrets_manager_secret_arn | The ARN of the Secrets Manager secret |
| secrets_manager_secret_name | The name of the Secrets Manager secret |
| access_key_id | The access key ID (sensitive) |
| iam_groups | The names of the IAM groups created |
| group_policy_arns | The ARNs of the group policies created |

## Secret Structure

The credentials are stored in Secrets Manager as a JSON object with the following structure:

```json
{
  "access_key_id": "AKIA...",
  "secret_access_key": "...",
  "username": "my-account-us-east-1-service-user",
  "created_date": "2024-01-01T00:00:00Z"
}
```

## Notes

- If access keys already exist for the user, the secret access key will show "*** EXISTING KEY - SECRET NOT AVAILABLE ***" since AWS doesn't allow retrieval of existing secret access keys
- The Python script handles both new key creation and existing key detection
- The module automatically tags all resources with common tags plus a Name tag
- Access keys are only created when `create_access_key` is set to `true`

## Security Considerations

- Secrets are stored with server-side encryption in AWS Secrets Manager
- Access key ID is marked as sensitive in Terraform outputs
- Secret access keys are never logged in Terraform state when they're from existing keys
- Consider using IAM roles instead of access keys when possible for better security