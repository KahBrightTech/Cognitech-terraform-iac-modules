terraform {
  required_version = ">= 1.5.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.37.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Advanced WAF configuration
module "advanced_waf" {
  source = "../../"

  common = {
    global = false
    tags = {
      Environment = var.environment
      Project     = var.project_name
      Owner       = var.owner
      Team        = var.team
    }
    account_name     = var.account_name
    region_prefix    = var.aws_region
    account_name_abr = var.account_name_abbreviation
  }

  waf = {
    create_waf                 = true
    name                       = "${var.project_name}-advanced-waf"
    description                = "Advanced WAF with comprehensive protection for ${var.project_name}"
    scope                      = "REGIONAL"
    default_action             = "allow"
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true

    # Custom managed rule groups with exclusions
    managed_rule_groups = [
      {
        name            = "AWSManagedRulesCommonRuleSet"
        priority        = 10
        vendor_name     = "AWS"
        exclude_rules   = var.core_rule_exclusions
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
      },
      {
        name            = "AWSManagedRulesAmazonIpReputationList"
        priority        = 40
        vendor_name     = "AWS"
        exclude_rules   = []
        override_action = "none"
      }
    ]

    # Custom rules for geographic and IP-based blocking
    custom_rules = [
      {
        name           = "BlockMaliciousCountries"
        priority       = 100
        action         = "block"
        statement_type = "geo_match"
        country_codes  = var.blocked_countries
      },
      {
        name           = "AllowTrustedIPs"
        priority       = 50
        action         = "allow"
        statement_type = "ip_set"
        ip_set_arn     = null # Will be populated after IP set creation
      }
    ]

    # Rate limiting rules
    rate_limit_rules = [
      {
        name               = "GeneralRateLimit"
        priority           = 200
        action             = var.rate_limit_action
        limit              = var.general_rate_limit
        aggregate_key_type = "IP"
      },
      {
        name               = "LoginPageRateLimit"
        priority           = 210
        action             = "block"
        limit              = var.login_rate_limit
        aggregate_key_type = "IP"
      }
    ]

    # IP Sets configuration
    ip_sets = {
      create_whitelist   = true
      whitelist_ips      = var.trusted_ip_ranges
      create_blacklist   = true
      blacklist_ips      = var.blocked_ip_ranges
      ip_address_version = "IPV4"
    }

    # ALB Association
    association = {
      associate_alb = var.associate_with_alb
      alb_arn       = var.alb_arn
    }

    # Comprehensive logging
    logging = {
      enabled            = true
      create_log_group   = true
      log_retention_days = var.log_retention_days
      redacted_fields    = var.log_redacted_fields
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

    additional_tags = {
      CostCenter    = var.cost_center
      SecurityLevel = "high"
      Example       = "advanced"
      Compliance    = var.compliance_tags
    }
  }
}