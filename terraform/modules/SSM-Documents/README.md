# SSM Documents Terraform Module

This Terraform module creates AWS Systems Manager (SSM) documents and optionally creates SSM associations to execute those documents on target instances.

## Features

- Creates SSM documents with customizable content
- Supports multiple document types (Command, Automation, Policy, etc.)
- Supports multiple document formats (YAML, JSON)
- Conditionally creates SSM associations
- Configurable targets for associations
- Support for parameters, scheduling, and output locations
- Automatic tagging with common tags

## Usage with Terragrunt

### Basic Usage (Document Only)

```hcl
# terragrunt.hcl
terraform {
  source = "git::https://github.com/your-org/terraform-modules//terraform/modules/SSM-Documents?ref=v1.0.0"
}

inputs = {
  common = {
    account_name_abr = "dev"
    region_prefix    = "use1"
    tags = {
      Environment = "development"
      Team        = "devops"
      Project     = "infrastructure"
    }
  }

  ssm_document = {
    name            = "install-cloudwatch-agent"
    content         = file("${get_terragrunt_dir()}/scripts/install-cloudwatch.yaml")
    document_type   = "Command"
    document_format = "YAML"
    
    # Association is not created by default
    create_association = false
  }
}
```

### Advanced Usage (Document with Association)

```hcl
# terragrunt.hcl
terraform {
  source = "git::https://github.com/your-org/terraform-modules//terraform/modules/SSM-Documents?ref=v1.0.0"
}

inputs = {
  common = {
    account_name_abr = "prod"
    region_prefix    = "use1"
    tags = {
      Environment = "production"
      Team        = "devops"
      Project     = "infrastructure"
    }
  }

  ssm_document = {
    name            = "security-patch-management"
    content         = file("${get_terragrunt_dir()}/scripts/security-patches.yaml")
    document_type   = "Command"
    document_format = "YAML"
    
    # Create association to run the document
    create_association = true
    
    # Target specific instances
    targets = {
      key    = "tag:Environment"
      values = ["production"]
    }
    
    # Pass parameters to the document
    parameters = {
      "Operation" = "Install"
      "Package"   = "cloudwatch-agent"
    }
    
    # Schedule execution (optional)
    schedule_expression = "cron(0 2 ? * SUN *)"  # Every Sunday at 2 AM
    
    # Store output in S3 (optional)
    output_location = {
      s3_bucket_name = "my-ssm-output-bucket"
      s3_key_prefix  = "ssm-execution-logs/"
    }
  }
}
```

### Multiple Documents Example

```hcl
# Directory structure:
# environments/
# ├── dev/
# │   ├── ssm-documents/
# │   │   ├── cloudwatch-agent/
# │   │   │   └── terragrunt.hcl
# │   │   └── security-patches/
# │   │       └── terragrunt.hcl
# └── prod/
#     └── ssm-documents/
#         ├── cloudwatch-agent/
#         │   └── terragrunt.hcl
#         └── security-patches/
#             └── terragrunt.hcl

# environments/dev/ssm-documents/cloudwatch-agent/terragrunt.hcl
include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "git::https://github.com/your-org/terraform-modules//terraform/modules/SSM-Documents?ref=v1.0.0"
}

inputs = {
  common = {
    account_name_abr = "dev"
    region_prefix    = "use1"
    tags = {
      Environment = "development"
      Purpose     = "monitoring"
    }
  }

  ssm_document = {
    name               = "cloudwatch-agent-install"
    content            = file("${get_terragrunt_dir()}/cloudwatch-config.yaml")
    create_association = true
    
    targets = {
      key    = "tag:MonitoringEnabled"
      values = ["true"]
    }
  }
}
```

## Input Variables

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `common` | object | Common configuration object |
| `common.account_name_abr` | string | Account name abbreviation for naming |
| `common.region_prefix` | string | Region prefix for naming |
| `common.tags` | map(string) | Common tags to apply to resources |
| `ssm_document` | object | SSM document configuration |
| `ssm_document.name` | string | Name of the SSM document |
| `ssm_document.content` | string | Content of the SSM document |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `ssm_document.document_type` | string | `"Command"` | Type of document (Command, Automation, Policy, etc.) |
| `ssm_document.document_format` | string | `"YAML"` | Format of document content (YAML, JSON) |
| `ssm_document.create_association` | bool | `false` | Whether to create an SSM association |
| `ssm_document.targets` | object | `null` | Target configuration for association |
| `ssm_document.parameters` | object | `null` | Parameters to pass to the document |
| `ssm_document.schedule_expression` | string | `null` | Cron/rate expression for scheduling |
| `ssm_document.output_location` | object | `null` | S3 location for storing command output |

### Targets Object Structure

```hcl
targets = {
  key    = "tag:Environment"        # Target key (tag:TagName, InstanceIds, etc.)
  values = ["production", "dev"]    # List of values to match
}
```

### Parameters Object Structure

```hcl
parameters = {
  "ParameterName1" = "ParameterValue1"     # Parameter as key-value pairs
  "ParameterName2" = "ParameterValue2"     # Each parameter takes a single string value
  "Operation"      = "Install"             # Example parameter
  "Package"        = "cloudwatch-agent"    # Example parameter
}
```

### Output Location Object Structure

```hcl
output_location = {
  s3_bucket_name = "my-bucket"      # S3 bucket name
  s3_key_prefix  = "logs/ssm/"      # S3 key prefix for logs
}
```

## Outputs

| Name | Description |
|------|-------------|
| `ssm_document_name` | Name of the created SSM document |
| `ssm_document_arn` | ARN of the created SSM document |
| `ssm_association_id` | ID of the SSM association (if created) |

## Document Content Examples

### CloudWatch Agent Installation (YAML)

```yaml
# scripts/install-cloudwatch.yaml
schemaVersion: '2.2'
description: Install and configure CloudWatch agent
parameters:
  configLocation:
    type: String
    description: S3 location of CloudWatch config
    default: 's3://my-bucket/cloudwatch-config.json'
mainSteps:
  - action: aws:downloadContent
    name: downloadCloudWatchConfig
    inputs:
      sourceType: S3
      sourceInfo:
        path: '{{ configLocation }}'
      destinationPath: /opt/aws/amazon-cloudwatch-agent/etc/
  - action: aws:runShellScript
    name: installCloudWatchAgent
    inputs:
      runCommand:
        - /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
```

### Security Patch Management (YAML)

```yaml
# scripts/security-patches.yaml
schemaVersion: '2.2'
description: Install security patches
parameters:
  Operation:
    type: String
    description: Patch operation
    allowedValues:
      - Install
      - Scan
    default: Scan
mainSteps:
  - action: aws:runPatchBaseline
    name: PatchInstance
    inputs:
      Operation: '{{ Operation }}'
      RebootOption: RebootIfNeeded
```

## How SSM Associations Execute

Understanding when and how your SSM documents execute is crucial for proper implementation:

### 1. **With Targets Only (No Schedule)**
```hcl
targets = {
  key    = "tag:Environment"
  values = ["production"]
}
# No schedule_expression specified
```
- The document runs **immediately** on all instances that match the target criteria
- It also runs on **new instances** that get the matching tag after the association is created
- This is event-driven execution

### 2. **With Schedule Only (No Targets)**
```hcl
schedule_expression = "cron(0 2 ? * SUN *)"  # Every Sunday at 2 AM
# No targets specified
```
- The document runs at the **scheduled time**
- It will run on **all instances** that have the SSM agent (no filtering)
- This is time-driven execution

### 3. **With Both Targets AND Schedule** (Most Common)
```hcl
targets = {
  key    = "tag:Environment"
  values = ["production"]
}
schedule_expression = "cron(0 2 ? * SUN *)"
```
- The document runs at the **scheduled time**
- But **only** on instances that match the target criteria
- This is the recommended approach for maintenance tasks

### 4. **No Targets, No Schedule**
```hcl
# Neither targets nor schedule_expression specified
```
- The document runs **immediately once** on all instances
- New instances won't automatically run it
- Less common pattern

### Key Execution Points:

- **Targets** = WHO (which instances)
- **Schedule** = WHEN (what time/frequency)
- If you have both, it runs on the specified instances at the scheduled time
- Without a schedule, it runs immediately and on new matching instances
- The SSM agent on target instances polls for new associations and executes them
- New instances that match the target criteria will automatically execute the document

## Best Practices

1. **Version Control**: Store document content in version-controlled files
2. **Testing**: Test documents in development environments first
3. **Scheduling**: Use appropriate schedules for maintenance windows
4. **Monitoring**: Enable output logging for troubleshooting
5. **Tagging**: Use consistent tagging for resource management
6. **Security**: Follow least-privilege principles for IAM roles

## Troubleshooting

### Common Issues

1. **Association fails to create**: Check if target instances exist and have SSM agent installed
2. **Document execution fails**: Verify IAM permissions and document syntax
3. **No targets found**: Ensure target tags/instances match the specified criteria

### Debugging

```bash
# Check SSM association status
aws ssm describe-association --association-id <association-id>

# View association execution history
aws ssm describe-association-executions --association-id <association-id>

# Check instance compliance
aws ssm list-compliance-items --resource-id <instance-id> --resource-type ManagedInstance
```

## Requirements

- Terraform >= 0.14
- AWS Provider >= 3.0
- Terragrunt >= 0.28
- AWS CLI configured with appropriate permissions

## Permissions Required

The AWS credentials must have the following permissions:
- `ssm:CreateDocument`
- `ssm:UpdateDocument`
- `ssm:DeleteDocument`
- `ssm:CreateAssociation`
- `ssm:UpdateAssociation`
- `ssm:DeleteAssociation`
- `ssm:DescribeAssociation*`
- `iam:PassRole` (if using service roles)

## License

This module is licensed under the MIT License.
