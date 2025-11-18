#--------------------------------------------------------------------
# Simple Terragrunt Example with JSON Rules - Block Cameroon, Allow IP
#--------------------------------------------------------------------
terraform {
  source = "../../"
}

include "root" {
  path = find_in_parent_folders()
}

locals {
  environment      = "dev"
  account_name    = "my-account"
  account_name_abr = "ma"
  region_prefix   = "use1"
  
  common_tags = {
    Environment = local.environment
    Project     = "Security"
    ManagedBy   = "Terragrunt"
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
    name           = "cameroon-blocking-waf"
    description    = "WAF to block Cameroon and allow office IP using JSON rules"
    scope          = "REGIONAL"
    default_action = "allow"

    # Load your custom JSON rule file
    json_rule_files = [
      "${get_terragrunt_dir()}/rules/country-blocking.json"
    ]

    # IP whitelist for your office IP
    ip_sets = {
      create_whitelist = true
      whitelist_ips    = ["10.113.40.30/32"]
    }

    # No ALB association (you can add this later)
    association = {
      associate_alb = false
      alb_arn       = null
    }

    # Basic logging
    logging = {
      enabled          = true
      create_log_group = true
      log_retention_days = 7
    }
  }
}