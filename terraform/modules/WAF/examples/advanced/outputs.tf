# WAF Outputs
output "waf_id" {
  description = "The ID of the WAF Web ACL"
  value       = module.advanced_waf.web_acl_id
}

output "waf_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = module.advanced_waf.web_acl_arn
}

output "waf_name" {
  description = "The name of the WAF Web ACL"
  value       = module.advanced_waf.web_acl_name
}

output "waf_capacity" {
  description = "The capacity units used by the WAF Web ACL"
  value       = module.advanced_waf.web_acl_capacity
}

# IP Sets Outputs
output "ip_whitelist_id" {
  description = "The ID of the IP whitelist"
  value       = module.advanced_waf.ip_whitelist_id
}

output "ip_whitelist_arn" {
  description = "The ARN of the IP whitelist"
  value       = module.advanced_waf.ip_whitelist_arn
}

output "ip_blacklist_id" {
  description = "The ID of the IP blacklist"
  value       = module.advanced_waf.ip_blacklist_id
}

output "ip_blacklist_arn" {
  description = "The ARN of the IP blacklist"
  value       = module.advanced_waf.ip_blacklist_arn
}

# Logging Outputs
output "log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = module.advanced_waf.log_group_name
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = module.advanced_waf.log_group_arn
}

# Association Outputs
output "web_acl_association_id" {
  description = "The ID of the WAF Web ACL association"
  value       = module.advanced_waf.web_acl_association_id
}

# Summary Outputs
output "waf_summary" {
  description = "Complete summary of WAF configuration"
  value       = module.advanced_waf.waf_summary
}

output "ip_sets_summary" {
  description = "Summary of IP sets configuration"
  value       = module.advanced_waf.ip_sets_summary
}

# Formatted outputs for easy consumption
output "waf_configuration" {
  description = "Formatted WAF configuration details"
  value = {
    web_acl = {
      id          = module.advanced_waf.web_acl_id
      arn         = module.advanced_waf.web_acl_arn
      name        = module.advanced_waf.web_acl_name
      capacity    = module.advanced_waf.web_acl_capacity
      description = module.advanced_waf.web_acl_description
      scope       = module.advanced_waf.web_acl_scope
    }
    ip_sets = {
      whitelist = {
        id  = module.advanced_waf.ip_whitelist_id
        arn = module.advanced_waf.ip_whitelist_arn
      }
      blacklist = {
        id  = module.advanced_waf.ip_blacklist_id
        arn = module.advanced_waf.ip_blacklist_arn
      }
    }
    logging = {
      log_group_name = module.advanced_waf.log_group_name
      log_group_arn  = module.advanced_waf.log_group_arn
    }
    association = {
      alb_association_id = module.advanced_waf.web_acl_association_id
    }
  }
}