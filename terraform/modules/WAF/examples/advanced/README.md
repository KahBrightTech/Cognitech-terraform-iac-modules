# Advanced WAF Example

This example demonstrates an advanced WAF configuration with custom rules, IP sets, rate limiting, and logging.

## Features

- Custom managed rule groups with exclusions
- IP whitelisting and blacklisting
- Geographic blocking
- Rate limiting rules
- Comprehensive logging with redaction
- ALB association

## Usage

1. Update the `terraform.tfvars` file with your values
2. Run the following commands:

```bash
terraform init
terraform plan
terraform apply
```

## Configuration Details

### Managed Rules
- AWS Core Rule Set (with exclusions)
- AWS Known Bad Inputs
- AWS SQL Injection Protection
- AWS IP Reputation List

### Custom Rules
- Geographic blocking (blocks traffic from specific countries)
- IP whitelist (allows specific trusted IPs)
- Rate limiting (general and login-specific)

### Logging
- CloudWatch Logs integration
- Field redaction for privacy
- 90-day retention policy

## Outputs

After applying, the module outputs comprehensive information about the created resources including WAF ARN, IP set details, and configuration summary.