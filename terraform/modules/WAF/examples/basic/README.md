# Basic WAF Example

This example demonstrates a basic WAF configuration with default AWS managed rules.

## Usage

```hcl
terraform init
terraform plan
terraform apply
```

## Configuration

```hcl
module "basic_waf" {
  source = "../"

  common = {
    global           = false
    tags = {
      Environment = "development"
      Project     = "web-app"
      Owner       = "dev-team"
    }
    account_name     = "mycompany"
    region_prefix    = "us-east-1"
    account_name_abr = "mc"
  }

  waf_name        = "basic-web-app-waf"
  waf_description = "Basic WAF for web application"
  scope           = "REGIONAL"
  default_action  = "allow"

  # Use default managed rules (AWS Common and Known Bad Inputs)
  # managed_rule_groups = null (uses defaults)

  # Enable CloudWatch metrics
  cloudwatch_metrics_enabled = true
  sampled_requests_enabled   = true

  additional_tags = {
    CostCenter = "development"
  }
}
```

## Outputs

After applying, you can reference the WAF outputs:

```hcl
output "waf_id" {
  value = module.basic_waf.web_acl_id
}

output "waf_arn" {
  value = module.basic_waf.web_acl_arn
}
```