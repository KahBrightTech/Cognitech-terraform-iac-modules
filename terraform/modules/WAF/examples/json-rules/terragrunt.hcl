#--------------------------------------------------------------------
# Terragrunt Configuration using JSON Rule Files
#--------------------------------------------------------------------
terraform {
  source = "../../"
}

include "root" {
  path = find_in_parent_folders()
}

locals {
  environment      = "dev"
  region          = "us-east-1" 
  region_prefix   = "use1"
  account_name    = "my-account"
  account_name_abr = "ma"
  
  # Paths to JSON rule files
  rule_files_path = get_terragrunt_dir()
  
  common_tags = {
    Environment = local.environment
    Project     = "Web Security"
    ManagedBy   = "Terragrunt"
    Owner       = "Security Team"
  }
}

inputs = {
  common = {
    global           = false
    tags             = local.common_tags
    account_name     = local.account_name
    region_prefix    = local.region_prefix
    account_name_abr = local.account_name_abr
  }

  waf = {
    create_waf      = true
    name           = "json-rules-waf"
    description    = "WAF using JSON rule files for configuration"
    scope          = "REGIONAL"
    default_action = "allow"
    
    # Load custom rules from JSON files
    rule_files = [
      "${local.rule_files_path}/rules/country-blocking.json",
      "${local.rule_files_path}/rules/security-rules.json",
      "${local.rule_files_path}/rules/rate-limiting.json"
    ]

    # IP whitelist for the office IP mentioned in country-blocking.json
    ip_sets = {
      create_whitelist = true
      whitelist_ips    = ["10.113.40.30/32"]
    }

    # Basic managed rules
    managed_rule_groups = [
      {
        name            = "AWSManagedRulesCommonRuleSet"
        priority        = 100
        vendor_name     = "AWS"
        exclude_rules   = []
        override_action = "none"
      }
    ]

    # No ALB association for this example
    association = {
      associate_alb = false
      alb_arn       = null
    }

    # Enable logging
    logging = {
      enabled          = true
      create_log_group = true
      log_retention_days = 14
    }
  }
}