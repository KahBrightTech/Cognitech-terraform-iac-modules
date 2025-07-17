# AWS Backup Module

This module creates AWS Backup resources including backup vault, backup plan, and backup selection with configurable selection tags.

## Usage

### Basic Usage with Default Selection Tags

```hcl
module "backup" {
  source = "./modules/AWSBackup"
  
  common = {
    global           = false
    tags             = { Environment = "prod" }
    account_name     = "my-account"
    region_prefix    = "us-east-1"
    account_name_abr = "myacc"
  }
  
  backup = {
    name = "my-backup-vault"
    plan = {
      schedule          = "cron(0 2 ? * * *)"  # Daily at 2 AM
      start_window      = 60
      completion_window = 120
      lifecycle = {
        delete_after = 30
      }
      selection = {
        selection_name = "my-backup-selection"
        # Using default tags: backup = "${region}-daily"
      }
    }
  }
}
```

### Advanced Usage with Custom Selection Tags

```hcl
module "backup" {
  source = "./modules/AWSBackup"
  
  common = {
    global           = false
    tags             = { Environment = "prod" }
    account_name     = "my-account"
    region_prefix    = "us-east-1"
    account_name_abr = "myacc"
  }
  
  backup = {
    name = "my-backup-vault"
    plan = {
      schedule          = "cron(0 2 ? * * *)"  # Daily at 2 AM
      start_window      = 60
      completion_window = 120
      lifecycle = {
        delete_after = 30
      }
      selection = {
        selection_name = "my-backup-selection"
        selection_tags = [
          {
            type  = "STRINGEQUALS"
            key   = "Environment"
            value = "production"
          },
          {
            type  = "STRINGEQUALS"
            key   = "BackupRequired"
            value = "true"
          },
          {
            type  = "STRINGNOTEQUALS"
            key   = "SkipBackup"
            value = "true"
          }
        ]
        resources = [
          "arn:aws:ec2:us-east-1:123456789012:instance/i-1234567890abcdef0"
        ]
      }
    }
  }
}
```

### Multiple Selection Tags Examples

```hcl
# Example 1: Backup all resources with specific tags
selection_tags = [
  {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "daily"
  },
  {
    type  = "STRINGEQUALS"
    key   = "Environment"
    value = "prod"
  }
]

# Example 2: Backup resources but exclude certain ones
selection_tags = [
  {
    type  = "STRINGEQUALS"
    key   = "BackupRequired"
    value = "true"
  },
  {
    type  = "STRINGNOTEQUALS"
    key   = "SkipBackup"
    value = "true"
  }
]

# Example 3: Backup by application
selection_tags = [
  {
    type  = "STRINGEQUALS"
    key   = "Application"
    value = "web-app"
  }
]
```

## Selection Tag Types

- `STRINGEQUALS`: Matches resources that have the specified tag key and value
- `STRINGNOTEQUALS`: Matches resources that don't have the specified tag key and value, or don't have the tag key at all

## Variables

### backup.plan.selection

| Name           | Type         | Default                                                            | Description                                        |
| -------------- | ------------ | ------------------------------------------------------------------ | -------------------------------------------------- |
| selection_name | string       | `"${account_name_abr}-${region_prefix}-backup-selection"`        | Name of the backup selection                       |
| selection_tags | list(object) | `[{type="STRINGEQUALS", key="backup", value="${region}-daily"}]` | List of tag conditions for resource selection      |
| resources      | list(string) | `[]`                                                             | Optional list of specific resource ARNs to include |

### selection_tags object

| Name  | Type   | Required | Description                                |
| ----- | ------ | -------- | ------------------------------------------ |
| type  | string | yes      | Either "STRINGEQUALS" or "STRINGNOTEQUALS" |
| key   | string | yes      | The tag key to match                       |
| value | string | yes      | The tag value to match                     |

## Outputs

| Name                | Description                |
| ------------------- | -------------------------- |
| backup_vault_arn    | ARN of the backup vault    |
| backup_plan_arn     | ARN of the backup plan     |
| backup_selection_id | ID of the backup selection |

## Examples

### Tag your resources for backup

```bash
# Tag an EC2 instance for daily backup
aws ec2 create-tags \
  --resources i-1234567890abcdef0 \
  --tags Key=Backup,Value=daily

# Tag an RDS instance for backup
aws rds add-tags-to-resource \
  --resource-name arn:aws:rds:us-east-1:123456789012:db:mydb \
  --tags Key=Environment,Value=production Key=BackupRequired,Value=true
```

## Notes

- If no `selection_tags` are provided, the module will use a default tag: `backup = "${region}-daily"`
- Multiple selection tags work with AND logic - all conditions must be met
- Resources must have all specified tags to be included in the backup
- The `resources` field can be used to explicitly specify resource ARNs if needed
