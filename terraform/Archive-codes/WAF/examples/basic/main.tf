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

# Basic WAF configuration
module "basic_waf" {
  source = "../../"

  common = {
    global = false
    tags = {
      Environment = var.environment
      Project     = var.project_name
      Owner       = var.owner
    }
    account_name     = var.account_name
    region_prefix    = var.aws_region
    account_name_abr = var.account_name_abbreviation
  }

  waf = {
    create_waf                 = true
    name                       = "${var.project_name}-basic-waf"
    description                = "Basic WAF for ${var.project_name} web application"
    scope                      = "REGIONAL"
    default_action             = "allow"
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
    additional_tags = {
      CostCenter = var.cost_center
      Example    = "basic"
    }
  }
}