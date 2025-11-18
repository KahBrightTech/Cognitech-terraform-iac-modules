# AWS WAF v2 Terraform Module

This Terraform module creates and manages AWS WAF v2 (Web Application Firewall) resources including Web ACLs, IP Sets, managed rule groups, custom rules, and logging configurations.

## Features

- ✅ **WAF v2 Web ACL** with flexible configuration
- ✅ **Managed Rule Groups** (AWS and third-party)
- ✅ **Custom Rules** (IP-based, geo-blocking, rate limiting, string matching)
- ✅ **IP Sets** (whitelist and blacklist)
- ✅ **Rate Limiting** with scope-down statements
- ✅ **ALB/CloudFront Association**
- ✅ **Comprehensive Logging** with filtering and redaction
- ✅ **CloudWatch Integration** with metrics and monitoring
- ✅ **Flexible Tagging**
- ✅ **Consolidated Configuration** using single `waf` variable

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

### Advanced WAF with Custom Rules and IP Sets

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

  waf_name        = "advanced-web-app-waf"
  waf_description = "Advanced WAF with custom rules and IP filtering"
  scope           = "REGIONAL"
  default_action  = "allow"

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
      name            = "AWSManagedRulesKnownBadInputsRuleSet"
      priority        = 20
      vendor_name     = "AWS"
      exclude_rules   = []
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

  # Custom rules
  custom_rules = [
    {
      name                  = "BlockSpecificCountries"
      priority              = 100
      action                = "block"
      statement_type        = "geo_match"
      country_codes         = ["CN", "RU", "KP"]
    },
    {
      name                  = "AllowWhitelistedIPs"
      priority              = 50
      action                = "allow"
      statement_type        = "ip_set"
      ip_set_arn           = module.waf_advanced.ip_whitelist_arn
    }
  ]

  # Rate limiting rules
  rate_limit_rules = [
    {
      name               = "GeneralRateLimit"
      priority           = 200
      action             = "block"
      limit              = 2000
      aggregate_key_type = "IP"
    },
    {
      name               = "LoginRateLimit"
      priority           = 210
      action             = "block"
      limit              = 100
      aggregate_key_type = "IP"
      scope_down_statement = {
        type           = "geo_match"
        country_codes  = ["US", "CA", "GB"]
      }
    }
  ]

  # IP Sets
  create_ip_whitelist = true
  whitelist_ips = [
    "203.0.113.0/24",
    "198.51.100.0/24"
  ]

  create_ip_blacklist = true
  blacklist_ips = [
    "192.0.2.44/32",
    "203.0.113.89/32"
  ]

  # ALB Association
  associate_alb = true
  alb_arn       = "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-alb/1234567890abcdef"

  # Logging
  enable_logging        = true
  create_log_group      = true
  log_retention_days    = 90
  redacted_fields       = ["uri_path", "query_string"]

  # Additional tags
  additional_tags = {
    CostCenter = "security"
    Owner      = "security-team"
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
| rate_limit_rules | List of rate limiting rules | `list(object)` | `[]` |
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