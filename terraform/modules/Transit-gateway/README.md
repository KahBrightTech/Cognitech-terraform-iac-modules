# Transit Gateway Module

This module creates AWS Transit Gateway with optional Resource Access Manager (RAM) sharing capabilities.

## Features

- Creates Transit Gateway with configurable settings
- Optional RAM sharing for cross-account access
- Support for multiple principals in RAM sharing
- Configurable external principal access
- Auto-accept shared attachments support

## Usage

### Basic Usage (No Sharing)

```hcl
module "transit_gateway" {
  source = "./modules/Transit-gateway"

  common = {
    global        = false
    tags          = local.common_tags
    account_name  = "my-account"
    region_prefix = "us-east-1"
    region        = "us-east-1"
  }

  transit_gateway = {
    name                            = "main"
    default_route_table_association = "enable"
    default_route_table_propagation = "enable"
    auto_accept_shared_attachments  = "enable"
    dns_support                     = "enable"
    amazon_side_asn                 = 64512
    vpc_name                        = "shared"
  }
}
```

### With RAM Sharing Enabled

```hcl
module "transit_gateway" {
  source = "./modules/Transit-gateway"

  common = {
    global        = false
    tags          = local.common_tags
    account_name  = "my-account"
    region_prefix = "us-east-1"
    region        = "us-east-1"
  }

  transit_gateway = {
    name                            = "main"
    default_route_table_association = "enable"
    default_route_table_propagation = "enable"
    auto_accept_shared_attachments  = "enable"
    dns_support                     = "enable"
    amazon_side_asn                 = 64512
    vpc_name                        = "shared"
    
    ram = {
      enabled                   = true
      share_name               = "my-transit-gateway-share"
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
| transit_gateway | Transit gateway configuration (includes RAM sharing options) | `object` | n/a | yes |

### Transit Gateway Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name for the transit gateway | `string` | n/a | yes |
| default_route_table_association | Enable or disable automatic route table association | `string` | n/a | yes |
| default_route_table_propagation | Enable or disable automatic route table propagation | `string` | n/a | yes |
| auto_accept_shared_attachments | Enable or disable auto-accept for shared attachments | `string` | n/a | yes |
| dns_support | Enable or disable DNS support | `string` | n/a | yes |
| amazon_side_asn | Private Autonomous System Number (ASN) for the Amazon side | `number` | n/a | yes |
| vpc_name | Name of the VPC | `string` | n/a | yes |
| ram | RAM sharing configuration object | `object` | `{ enabled = false }` | no |

### RAM Object Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enabled | Enable RAM sharing for the Transit Gateway | `bool` | `false` | no |
| share_name | Name of the RAM resource share | `string` | `"transit-gateway-share"` | no |
| allow_external_principals | Allow sharing with external AWS accounts | `bool` | `false` | no |
| principals | List of AWS account IDs or organization ARNs to share with | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| transit_gateway_id | The ID of the transit gateway |
| tgw_arn | The ARN of the transit gateway |
| ram_resource_share_arn | The ARN of the RAM resource share (if enabled) |
| ram_resource_share_id | The ID of the RAM resource share (if enabled) |
| ram_sharing_enabled | Whether RAM sharing is enabled |

## Notes

- When `ram.enabled` is `true`, the Transit Gateway will be automatically shared via RAM
- The `ram.principals` list can contain AWS account IDs (12-digit numbers) or organization ARNs
- Set `ram.allow_external_principals` to `true` if sharing with accounts outside your AWS organization
- RAM sharing allows other accounts to create attachments to the shared Transit Gateway
- The `ram` object is optional - if not provided, sharing will be disabled by default
- Set `auto_accept_shared_attachments` to `"enable"` to automatically accept attachments from shared accounts