# AWS Resource Access Manager (RAM) Module

This Terraform module creates AWS Resource Access Manager (RAM) resource shares to share AWS resources with other AWS accounts or organization units within your AWS Organization.

## Features

- **Flexible Resource Sharing**: Share any AWS resource that supports RAM sharing
- **Multiple Resource Support**: Share multiple resources in a single resource share
- **Cross-Account Sharing**: Share resources with specific AWS account IDs
- **Organization Sharing**: Share resources with organization units (requires AWS Organizations)
- **Comprehensive Validation**: Built-in validation for principals and resource configuration
- **Conditional Creation**: Enable/disable RAM sharing with a single flag

## Supported AWS Resources

This module can share any AWS resource that supports RAM sharing, including but not limited to:

- **VPC Resources**: Subnets, Transit Gateways, VPC Peering Connections
- **Route 53**: Resolver Rules, Resolver Endpoints
- **License Manager**: License Configurations
- **App Mesh**: Meshes
- **Resource Groups**: Resource Groups
- **CodeBuild**: Projects, Report Groups
- **EC2**: Dedicated Hosts, Capacity Reservations
- **Aurora**: Clusters (for Aurora Serverless v1)

## Usage

### Basic Example - Transit Gateway Sharing

```hcl
module "ram_share" {
  source = "./modules/RAM"

  common = {
    global           = true
    account_name     = "production"
    region_prefix    = "us-east-1"
    account_name_abr = "prod"
    tags = {
      Environment = "production"
      Project     = "networking"
    }
  }

  ram = {
    enabled                   = true
    share_name               = "TGW-CrossAccount-Share"
    allow_external_principals = true
    resource_arns = [
      "arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0123456789abcdef0"
    ]
    principals = [
      "987654321098",  # Development account
      "456789012345"   # Staging account
    ]
  }
}
```

### Advanced Example - Multiple Resources

```hcl
module "ram_share" {
  source = "./modules/RAM"

  common = {
    global           = true
    account_name     = "production"
    region_prefix    = "us-east-1"
    account_name_abr = "prod"
    tags = {
      Environment = "production"
      Project     = "shared-infrastructure"
    }
  }

  ram = {
    enabled                   = true
    share_name               = "SharedInfra-CrossAccount"
    allow_external_principals = true
    resource_arns = [
      "arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0123456789abcdef0",
      "arn:aws:ec2:us-east-1:123456789012:subnet/subnet-0123456789abcdef0",
      "arn:aws:route53resolver:us-east-1:123456789012:resolver-rule/rslvr-rr-0123456789abcdef0"
    ]
    principals = [
      "987654321098",
      "456789012345",
      "321098765432"
    ]
  }
}
```

### Organization Unit Sharing

```hcl
module "ram_share" {
  source = "./modules/RAM"

  common = {
    global           = true
    account_name     = "master"
    region_prefix    = "us-east-1"
    account_name_abr = "master"
    tags = {
      Environment = "organization"
      Project     = "shared-services"
    }
  }

  ram = {
    enabled                   = true
    share_name               = "OrgUnit-SharedServices"
    allow_external_principals = false  # Internal to organization
    resource_arns = [
      "arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0123456789abcdef0"
    ]
    principals = [
      "ou-root-123456789"  # Organization unit ID
    ]
  }
}
```

### Disabled Sharing

```hcl
module "ram_share" {
  source = "./modules/RAM"

  common = {
    global           = true
    account_name     = "development"
    region_prefix    = "us-east-1"
    account_name_abr = "dev"
    tags = {
      Environment = "development"
    }
  }

  ram = {
    enabled                   = false
    share_name               = "Dev-NoSharing"
    allow_external_principals = true
    resource_arns            = []
    principals               = []
  }
}
```

## Variables

### Common Variables

| Name | Description | Type | Required |
|------|-------------|------|----------|
| common.global | Whether this is a global resource | `bool` | Yes |
| common.tags | A map of tags to assign to resources | `map(string)` | Yes |
| common.account_name | Name of the AWS account | `string` | Yes |
| common.region_prefix | AWS region prefix | `string` | Yes |
| common.account_name_abr | Abbreviated account name | `string` | No |

### RAM Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| ram.enabled | Whether to enable RAM resource sharing | `bool` | - | Yes |
| ram.share_name | Name of the resource share | `string` | - | Yes |
| ram.allow_external_principals | Whether to allow external principals | `bool` | `true` | No |
| ram.resource_arns | List of resource ARNs to share | `list(string)` | - | Yes* |
| ram.principals | List of principals to share with | `list(string)` | - | Yes* |

*Required when `enabled = true`

## Outputs

| Name | Description |
|------|-------------|
| resource_share_arn | The ARN of the resource share |
| resource_share_id | The ID of the resource share |
| resource_share_name | The name of the resource share |
| resource_share_status | The status of the resource share |
| associated_resources | List of resource ARNs associated with the share |
| associated_principals | List of principals associated with the share |
| allow_external_principals | Whether the resource share allows external principals |
| sharing_enabled | Whether RAM sharing is enabled |

## Validation Rules

The module includes comprehensive validation:

1. **Share Name**: Must not be empty
2. **Resource ARNs**: At least one resource ARN required when sharing is enabled
3. **Principals**: At least one principal required when sharing is enabled
4. **Principal Format**: Must be valid AWS account IDs (12 digits), organization IDs (o-xxxxxxxxxx), or organizational unit IDs (ou-xxxxxxxxxxxxxxxx)

## Prerequisites

### AWS Organizations (for OU sharing)
If sharing with organization units, ensure:
1. AWS Organizations is set up
2. RAM sharing is enabled in organization settings
3. Proper permissions for resource sharing

### External Account Sharing
For cross-account sharing:
1. Target accounts must accept the resource share invitation
2. Ensure proper IAM permissions in both source and target accounts

## Resource Share Acceptance

After creating a resource share:

1. **Manual Acceptance**: Target accounts receive invitations that must be accepted manually
2. **Automatic Acceptance**: Can be configured in AWS Organizations for internal sharing
3. **CLI Acceptance**: Use AWS CLI in target accounts:
   ```bash
   aws ram accept-resource-share-invitation --resource-share-invitation-arn <invitation-arn>
   ```

## Best Practices

1. **Naming Convention**: Use descriptive names for resource shares
2. **Least Privilege**: Only share resources that need to be shared
3. **Monitoring**: Monitor resource share usage and access
4. **Documentation**: Document what resources are shared and why
5. **Regular Review**: Periodically review and clean up unused shares

## Common Use Cases

### 1. Centralized Transit Gateway
Share a central Transit Gateway with multiple accounts for hub-and-spoke network architecture.

### 2. Shared Subnets
Share subnets for centralized networking or cost optimization.

### 3. DNS Resolution
Share Route 53 resolver rules for centralized DNS resolution.

### 4. License Management
Share License Manager configurations across accounts.

## Troubleshooting

### Common Issues

1. **Principal Validation Error**: Ensure account IDs are exactly 12 digits
2. **Resource Not Shareable**: Verify the resource type supports RAM sharing
3. **Permission Denied**: Ensure proper IAM permissions for RAM operations
4. **Organization Sharing Failed**: Verify AWS Organizations is properly configured

### Debugging

```bash
# List resource shares
aws ram get-resource-shares --resource-owner SELF

# Check resource share invitations
aws ram get-resource-share-invitations

# Verify resource associations
aws ram get-resource-share-associations --association-type RESOURCE
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.5 |
| aws | >= 4.37.0 |

## License

This module is licensed under the MIT License.