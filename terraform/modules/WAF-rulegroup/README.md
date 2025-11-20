# AWS WAF v2 Rule Groups Terraform Module

This Terraform module creates and manages AWS WAF v2 Rule Groups only. This module is focused specifically on creating rule groups that can be referenced by WAF Web ACLs.

## Features

- ✅ **WAF v2 Rule Groups** with flexible configuration
- ✅ **Custom Rules** (IP-based, geo-blocking, rate limiting, string matching)
- ✅ **JSON Configuration** for rule groups
- ✅ **Multiple Statement Types** (SQL injection, XSS, byte match, etc.)
- ✅ **Flexible Tagging**

## Usage

### Basic Rule Group

```hcl
module "waf_rule_groups" {
  source = "./modules/WAF-rulegroup"

  common = {
    global           = false
    tags             = {
      Environment = "production"
      Project     = "web-app"
    }
    account_name     = "mycompany"
    region_prefix    = "us-east-1"
    account_name_abr = "mc"
  }

  scope = "REGIONAL"

  rule_groups = [
    {
      name        = "security-rules"
      description = "Security rules for application protection"
      capacity    = 100
      rules = [
        {
          name           = "BlockSQLInjection"
          priority       = 1
          action         = "block"
          statement_type = "sqli_match"
          field_to_match = "body"
          text_transformation = "URL_DECODE"
        },
        {
          name           = "BlockXSS"
          priority       = 2
          action         = "block"
          statement_type = "xss_match"
          field_to_match = "uri_path"
          text_transformation = "HTML_ENTITY_DECODE"
        }
      ]
    }
  ]
}
```

### Rule Group with JSON Configuration

```hcl
module "waf_rule_groups_json" {
  source = "./modules/WAF-rulegroup"

  common = {
    global           = false
    tags             = {
      Environment = "production"
      Project     = "web-app"
    }
    account_name     = "mycompany"
    region_prefix    = "us-west-2"
    account_name_abr = "mc"
  }

  scope = "REGIONAL"

  # Load rule groups from JSON files
  rule_group_files = [
    "${path.module}/rules/security-rules.json",
    "${path.module}/rules/rate-limiting.json"
  ]

  rule_groups = [
    {
      name        = "geo-blocking-rules"
      description = "Geographic blocking rules"
      capacity    = 50
      rules = [
        {
          name                  = "BlockSpecificCountries"
          priority              = 1
          action                = "block"
          statement_type        = "geo_match"
          country_codes         = ["CN", "RU", "KP"]
        }
      ]
    }
  ]

  additional_tags = {
    CostCenter = "security"
    Owner      = "security-team"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.5 |
| aws | >= 4.37.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.37.0 |

## Inputs

### Required Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| common | Common variables used by all resources | `object` | n/a |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| scope | Scope of the WAF (CLOUDFRONT or REGIONAL) | `string` | `"REGIONAL"` |
| rule_groups | List of rule groups to create | `list(object)` | `[]` |
| rule_group_files | List of JSON file paths containing rule group configurations | `list(string)` | `[]` |
| additional_tags | Additional tags to apply to all resources | `map(string)` | `{}` |

## Outputs

### Primary Outputs

| Name | Description |
|------|-------------|
| rule_groups | Map of all rule groups created |
| rule_group_ids | Map of rule group IDs |
| rule_group_names | Map of rule group names |
| rule_group_arns | Map of rule group ARNs |
| rule_group_capacities | Map of rule group capacities |
| rule_groups_summary | Summary of rule groups configuration |

## Rule Types Supported

### Custom Rule Types
- **SQL Injection Match**: Detect and block SQL injection attempts
- **XSS Match**: Detect and block cross-site scripting attempts
- **Byte Match**: Block based on URI, headers, or body content
- **Size Constraint**: Limit request size
- **IP Set Reference**: Allow/block based on IP sets (requires external IP set ARN)
- **Geo Match**: Block traffic from specific countries
- **Rate Limiting**: Limit requests per IP

## JSON Configuration

### Rule Groups from JSON Files

You can load rule groups from JSON files using the `rule_group_files` parameter:

```hcl
rule_group_files = [
  "${path.module}/rules/security-rules.json",
  "${path.module}/rules/rate-limiting.json"
]
```

### JSON File Format

Example JSON structure for rule groups:

```json
{
  "rule_groups": [
    {
      "name": "custom-security-rules",
      "description": "Custom security rules for application protection",
      "capacity": 100,
      "rules": [
        {
          "name": "BlockSQLInjection",
          "priority": 1,
          "action": "block",
          "statement_type": "sqli_match",
          "field_to_match": "body",
          "text_transformation": "URL_DECODE"
        },
        {
          "name": "BlockXSS",
          "priority": 2,
          "action": "block",
          "statement_type": "xss_match",
          "field_to_match": "uri_path",
          "text_transformation": "HTML_ENTITY_DECODE"
        },
        {
          "name": "RateLimitPerIP",
          "priority": 3,
          "action": "block",
          "statement_type": "rate_limit",
          "rate_limit": 2000,
          "aggregate_key_type": "IP"
        }
      ]
    }
  ]
}
```

## Best Practices

1. **Plan Capacity**: WAF rule groups have capacity limits, plan your rules accordingly
2. **Test in Count Mode**: Use `count` action before `block` to test rules
3. **Organize by Function**: Group related rules together in logical rule groups
4. **Use Descriptive Names**: Use clear naming conventions for rules and rule groups
5. **Monitor Performance**: Rule groups with high capacity may impact performance

## License

This module is released under the MIT License. See LICENSE file for details.
````

## Usage

### Basic WAF with Default Managed Rules

```hcl
module "waf" {
  source = "./modules/WAF"

  common = {
    global           = false
    tags             = {
      Environment = "production"
      Project     = "web-app"
    }
    account_name     = "mycompany"
    region_prefix    = "us-east-1"
    account_name_abr = "mc"
  }

  waf_name        = "web-app-waf"
  waf_description = "WAF for web application protection"
  scope           = "REGIONAL"
  default_action  = "allow"

  # Enable ALB association
  associate_alb = true
  alb_arn       = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/my-alb/1234567890abcdef"
}
```

### Advanced WAF with Custom Rules, Rule Groups and IP Sets

```hcl
module "waf_advanced" {
  source = "./modules/WAF"

  common = {
    global           = false
    tags             = {
      Environment = "production"
      Project     = "web-app"
      Team        = "security"
    }
    account_name     = "mycompany"
    region_prefix    = "us-west-2"
    account_name_abr = "mc"
  }

  waf = {
    create_waf    = true
    name          = "advanced-web-app-waf"
    description   = "Advanced WAF with custom rules and rule groups"
    scope         = "REGIONAL"
    default_action = "allow"

    # Custom managed rule groups
    managed_rule_groups = [
      {
        name            = "AWSManagedRulesCommonRuleSet"
        priority        = 10
        vendor_name     = "AWS"
        exclude_rules   = ["SizeRestrictions_BODY", "GenericRFI_BODY"]
        override_action = "none"
      },
      {
        name            = "AWSManagedRulesSQLiRuleSet"
        priority        = 30
        vendor_name     = "AWS"
        exclude_rules   = []
        override_action = "none"
      }
    ]

    # Custom rule groups
    rule_groups = [
      {
        create      = true
        name        = "custom-security-rules"
        description = "Custom security rules for application protection"
        capacity    = 100
        rules = [
          {
            name           = "BlockSQLInjection"
            priority       = 1
            action         = "block"
            statement_type = "sqli_match"
            field_to_match = "body"
            text_transformation = "URL_DECODE"
          },
          {
            name           = "BlockXSS"
            priority       = 2
            action         = "block"
            statement_type = "xss_match"
            field_to_match = "uri_path"
            text_transformation = "HTML_ENTITY_DECODE"
          }
        ]
      }
    ]

    # Load rule groups from JSON files
    rule_group_files = [
      "${path.module}/rules/security-rules.json",
      "${path.module}/rules/rate-limiting.json"
    ]

    # Reference rule groups (both internal and external)
    rule_group_references = [
      {
        name            = "InternalRuleGroup"
        priority        = 100
        rule_group_key  = "security-rules"  # References rule group created in this module
        override_action = "none"
      },
      {
        name            = "ExternalSecurityRules"
        priority        = 110
        rule_group_arn  = "arn:aws:wafv2:us-west-2:123456789012:regional/rulegroup/external-rules/12345678-1234-1234-1234-123456789012"
        override_action = "none"
      }
    ]

    # Custom rules
    custom_rules = [
      {
        name                  = "BlockSpecificCountries"
        priority              = 200
        action                = "block"
        statement_type        = "geo_match"
        country_codes         = ["CN", "RU", "KP"]
      }
    ]

    # IP Sets
    ip_sets = [
      {
        create             = true
        name               = "allowed-ips"
        description        = "Allowed IP addresses"
        type               = "whitelist"
        ip_address_version = "IPV4"
        addresses          = ["203.0.113.0/24", "198.51.100.0/24"]
      },
      {
        create             = true
        name               = "blocked-ips"
        description        = "Blocked IP addresses"
        type               = "blacklist"
        ip_address_version = "IPV4"
        addresses          = ["192.0.2.44/32", "203.0.113.89/32"]
      }
    ]

    # ALB Association
    association = {
      associate_alb = true
      alb_arn       = "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-alb/1234567890abcdef"
    }

    # Logging
    logging = {
      enabled             = true
      create_log_group    = true
      log_retention_days  = 90
      redacted_fields     = ["uri_path", "query_string"]
    }

    # Additional tags
    additional_tags = {
      CostCenter = "security"
      Owner      = "security-team"
    }
  }
}
```

### CloudFront WAF Configuration

```hcl
module "cloudfront_waf" {
  source = "./modules/WAF"

  # Note: CloudFront WAFs must be created in us-east-1
  providers = {
    aws = aws.us-east-1
  }

  common = {
    global           = true
    tags             = {
      Environment = "production"
      Project     = "cdn"
    }
    account_name     = "mycompany"
    region_prefix    = "global"
    account_name_abr = "mc"
  }

  waf_name        = "cloudfront-waf"
  waf_description = "WAF for CloudFront distribution"
  scope           = "CLOUDFRONT"  # Important for CloudFront
  default_action  = "allow"

  # CloudFront-specific managed rules
  managed_rule_groups = [
    {
      name            = "AWSManagedRulesCommonRuleSet"
      priority        = 10
      vendor_name     = "AWS"
      exclude_rules   = []
      override_action = "none"
    },
    {
      name            = "AWSManagedRulesAmazonIpReputationList"
      priority        = 20
      vendor_name     = "AWS"
      exclude_rules   = []
      override_action = "none"
    }
  ]

  # Enable logging to S3
  enable_logging     = true
  log_destination_arn = "arn:aws:s3:::my-waf-logs-bucket"

  logging_filter = {
    default_behavior = "KEEP"
    filters = [
      {
        behavior    = "DROP"
        requirement = "MEETS_ALL"
        conditions = [
          {
            type   = "action"
            action = "ALLOW"
          }
        ]
      }
    ]
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.5 |
| aws | >= 4.37.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.37.0 |

## Inputs

### Required Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| common | Common variables used by all resources | `object` | n/a |

### Optional Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| create_waf | Whether to create the WAF Web ACL | `bool` | `true` |
| waf_name | Name of the WAF Web ACL | `string` | `null` (auto-generated) |
| waf_description | Description of the WAF Web ACL | `string` | `"WAF Web ACL for application protection"` |
| scope | Scope of the WAF (CLOUDFRONT or REGIONAL) | `string` | `"REGIONAL"` |
| default_action | Default action (allow or block) | `string` | `"allow"` |
| managed_rule_groups | List of managed rule groups | `list(object)` | AWS Common and Known Bad Inputs |
| custom_rules | List of custom rules | `list(object)` | `[]` |
| create_ip_whitelist | Whether to create IP whitelist | `bool` | `false` |
| create_ip_blacklist | Whether to create IP blacklist | `bool` | `false` |
| whitelist_ips | List of IPs to whitelist | `list(string)` | `[]` |
| blacklist_ips | List of IPs to blacklist | `list(string)` | `[]` |
| associate_alb | Whether to associate with ALB | `bool` | `false` |
| alb_arn | ARN of ALB to associate | `string` | `null` |
| enable_logging | Whether to enable logging | `bool` | `false` |
| create_log_group | Whether to create CloudWatch log group | `bool` | `false` |

## Outputs

### Primary Outputs

| Name | Description |
|------|-------------|
| web_acl_id | ID of the WAF Web ACL |
| web_acl_arn | ARN of the WAF Web ACL |
| web_acl_name | Name of the WAF Web ACL |
| web_acl_capacity | Capacity units used by the Web ACL |

### IP Sets Outputs

| Name | Description |
|------|-------------|
| ip_whitelist_id | ID of the IP whitelist |
| ip_whitelist_arn | ARN of the IP whitelist |
| ip_blacklist_id | ID of the IP blacklist |
| ip_blacklist_arn | ARN of the IP blacklist |

### Summary Outputs

| Name | Description |
|------|-------------|
| waf_summary | Complete summary of WAF configuration |
| ip_sets_summary | Summary of IP sets configuration |

## Rule Types Supported

### Managed Rule Groups
- AWS Core Rule Set
- AWS Known Bad Inputs
- AWS SQL Injection Protection
- AWS Amazon IP Reputation List
- AWS Anonymous IP List
- Third-party rule groups

### Custom Rule Groups
Create custom rule groups with configurable capacity and rules:
- **SQL Injection Match**: Detect and block SQL injection attempts
- **XSS Match**: Detect and block cross-site scripting attempts
- **Byte Match**: Block based on URI, headers, or body content
- **Size Constraint**: Limit request size
- **IP Set Reference**: Allow/block based on IP sets
- **Geo Match**: Block traffic from specific countries
- **Rate Limiting**: Limit requests per IP

### Custom Rule Types
- **IP Set Rules**: Allow/block based on IP sets
- **Geo Match Rules**: Block traffic from specific countries
- **Rate Limiting Rules**: Limit requests per IP/session
- **String Match Rules**: Block based on URI, headers, or body content
- **Size Constraint Rules**: Limit request size

### Rate Limiting
- Per-IP rate limiting
- Geographic rate limiting
- URI-based rate limiting
- Custom aggregation keys

## JSON Configuration

### Rule Groups from JSON Files

You can load rule groups from JSON files using the `rule_group_files` parameter:

```hcl
waf = {
  rule_group_files = [
    "${path.module}/rules/security-rules.json",
    "${path.module}/rules/rate-limiting.json"
  ]
}
```

### JSON File Format

Example JSON structure for rule groups:

```json
{
  "rule_groups": [
    {
      "create": true,
      "name": "custom-security-rules",
      "description": "Custom security rules for application protection",
      "capacity": 100,
      "rules": [
        {
          "name": "BlockSQLInjection",
          "priority": 1,
          "action": "block",
          "statement_type": "sqli_match",
          "field_to_match": "body",
          "text_transformation": "URL_DECODE"
        },
        {
          "name": "BlockXSS",
          "priority": 2,
          "action": "block",
          "statement_type": "xss_match",
          "field_to_match": "uri_path",
          "text_transformation": "HTML_ENTITY_DECODE"
        }
      ]
    }
  ]
}
```

See `examples/rule-groups-example.json` for a complete example with all supported rule types.

## Logging and Monitoring

### Supported Log Destinations
- Amazon CloudWatch Logs
- Amazon S3
- Amazon Kinesis Data Firehose

### Log Filtering
- Field redaction (URI, headers, query strings)
- Conditional logging based on action or rule labels
- Sampling configuration

### CloudWatch Integration
- Custom metrics for each rule
- Sampled request logging
- Dashboard-ready metric names

## Best Practices

1. **Start with AWS Managed Rules**: Begin with AWS-managed rule groups and customize as needed
2. **Test in Count Mode**: Use `count` action before `block` to test rules
3. **Monitor Capacity**: WAF has a 1500 WCU (Web ACL Capacity Units) limit
4. **Use IP Sets Efficiently**: Group similar IPs in IP sets rather than individual rules
5. **Enable Logging**: Always enable logging for security analysis
6. **Regular Review**: Periodically review and update rules based on logs
7. **Rate Limiting**: Implement rate limiting to prevent DDoS attacks
8. **Geo-blocking**: Block known malicious countries if appropriate for your application

## Security Considerations

- Store sensitive data (API keys, secrets) in AWS Systems Manager Parameter Store
- Use least privilege IAM policies for WAF management
- Regularly update managed rule groups
- Monitor for false positives and adjust rules accordingly
- Implement proper alerting for blocked requests

## Cost Optimization

- Use managed rules instead of custom rules when possible (lower cost)
- Optimize rule priority to process most common matches first
- Use IP sets for multiple IP-based rules
- Consider request sampling for logging to reduce costs

## Troubleshooting

### Common Issues

1. **Capacity Exceeded**: Reduce rule complexity or remove unused rules
2. **False Positives**: Use count mode to test, add exceptions for legitimate traffic
3. **CloudFront Integration**: Ensure WAF is created in us-east-1 for CloudFront
4. **Logging Not Working**: Check log destination permissions and configuration

### Debug Commands

```bash
# Check Web ACL details
aws wafv2 describe-web-acl --scope REGIONAL --id <web-acl-id>

# List sampled requests
aws wafv2 get-sampled-requests --web-acl-arn <web-acl-arn> --rule-metric-name <metric-name> --scope REGIONAL --time-window StartTime=<start>,EndTime=<end>

# Check capacity usage
aws wafv2 check-capacity --scope REGIONAL --rules file://rules.json
```

## License

This module is released under the MIT License. See LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review AWS WAF documentation
3. Open an issue in the repository
4. Contact the module maintainers