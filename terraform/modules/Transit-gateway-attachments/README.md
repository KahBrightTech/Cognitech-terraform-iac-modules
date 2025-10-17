# Transit Gateway Attachments Module

This module creates AWS Transit Gateway VPC attachments with optional Resource Access Manager (RAM) sharing capabilities.

## Features

- Creates Transit Gateway VPC attachments
- Optional RAM sharing for cross-account access
- Support for multiple principals in RAM sharing
- Configurable external principal access

## Usage

### Basic Usage (No Sharing)

```hcl
module "tgw_attachment" {
  source = "./modules/Transit-gateway-attachments"

  common = {
    global        = false
    tags          = local.common_tags
    account_name  = "my-account"
    region_prefix = "us-east-1"
    region        = "us-east-1"
  }

  vpc_id = "vpc-12345678"
  
  tgw_attachments = {
    transit_gateway_id = "tgw-12345678"
    subnet_ids         = ["subnet-12345678", "subnet-87654321"]
    name              = "my-tgw-attachment"
  }
}
```

### With RAM Sharing Enabled

```hcl
module "tgw_attachment" {
  source = "./modules/Transit-gateway-attachments"

  common = {
    global        = false
    tags          = local.common_tags
    account_name  = "my-account"
    region_prefix = "us-east-1"
    region        = "us-east-1"
  }

  vpc_id = "vpc-12345678"
  
  tgw_attachments = {
    transit_gateway_id = "tgw-12345678"
    subnet_ids         = ["subnet-12345678", "subnet-87654321"]
    name              = "my-shared-tgw-attachment"
    
    ram = {
      enabled                   = true
      share_name               = "my-tgw-attachment-share"
      allow_external_principals = true
      principals               = [
        "123456789012",  # Account ID
        "arn:aws:organizations::123456789012:account/o-example123456/234567890123"  # Organization account ARN
      ]
    }
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| common | Common variables used by all resources | `object` | n/a | yes |
| vpc_id | The VPC ID to attach to the transit gateway | `string` | n/a | yes |
| tgw_attachments | Transit gateway attachment configuration (includes RAM sharing options) | `object` | n/a | yes |

### TGW Attachments Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| transit_gateway_id | ID of the transit gateway | `string` | n/a | yes |
| subnet_ids | List of subnet IDs for the attachment | `list(string)` | n/a | yes |
| transit_gateway_name | Name of the transit gateway | `string` | `null` | no |
| name | Name for the TGW attachment | `string` | `null` | no |
| shared_vpc_name | Name of the shared VPC | `string` | `null` | no |
| customer_vpc_name | Name of the customer VPC | `string` | `null` | no |
| ram | RAM sharing configuration object | `object` | `{ enabled = false }` | no |

### RAM Object Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Enable RAM sharing for the TGW attachment | `bool` | `false` | no |
| share_name | Name of the RAM resource share | `string` | `"tgw-attachment-share"` | no |
| allow_external_principals | Allow sharing with external AWS accounts | `bool` | `false` | no |
| principals | List of AWS account IDs or organization ARNs to share with | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| tgw_attachment_id | The ID of the transit gateway attachment |
| tgw_attachment_arn | The ARN of the transit gateway attachment |
| ram_resource_share_arn | The ARN of the RAM resource share (if enabled) |
| ram_resource_share_id | The ID of the RAM resource share (if enabled) |
| ram_sharing_enabled | Whether RAM sharing is enabled |

## Notes

- When `ram.enabled` is `true`, the TGW attachment will be automatically shared via RAM
- The `ram.principals` list can contain AWS account IDs (12-digit numbers) or organization ARNs
- Set `ram.allow_external_principals` to `true` if sharing with accounts outside your AWS organization
- RAM sharing allows other accounts to see and use the TGW attachment in their route tables
- The `ram` object is optional - if not provided, sharing will be disabled by default
- All RAM-related configuration is now organized within a nested `ram` object for better structure