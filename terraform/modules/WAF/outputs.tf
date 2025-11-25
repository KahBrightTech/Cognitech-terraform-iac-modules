#--------------------------------------------------------------------
# AWS WAF Web ACL Outputs
#--------------------------------------------------------------------
output "web_acl_id" {
  description = "The ID of the WAF Web ACL"
  value       = var.waf.create_waf ? aws_wafv2_web_acl.main[0].id : null
}

output "web_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = var.waf.create_waf ? aws_wafv2_web_acl.main[0].arn : null
}

output "web_acl_name" {
  description = "The name of the WAF Web ACL"
  value       = var.waf.create_waf ? aws_wafv2_web_acl.main[0].name : null
}

output "web_acl_capacity" {
  description = "The capacity of the WAF Web ACL"
  value       = var.waf.create_waf ? aws_wafv2_web_acl.main[0].capacity : null
}

output "web_acl_description" {
  description = "The description of the WAF Web ACL"
  value       = var.waf.create_waf ? aws_wafv2_web_acl.main[0].description : null
}

output "web_acl_scope" {
  description = "The scope of the WAF Web ACL"
  value       = var.waf.create_waf ? aws_wafv2_web_acl.main[0].scope : null
}

output "web_acl_tags" {
  description = "The tags applied to the WAF Web ACL"
  value       = var.waf.create_waf ? aws_wafv2_web_acl.main[0].tags_all : {}
}

#--------------------------------------------------------------------
# Association Outputs
#--------------------------------------------------------------------
output "web_acl_association_id" {
  description = "The ID of the WAF Web ACL association"
  value       = var.waf.association.associate_alb && var.waf.association.alb_arns != null ? [for k, v in aws_wafv2_web_acl_association.main : v.id] : []
}

#--------------------------------------------------------------------
# Logging Outputs
#--------------------------------------------------------------------
output "logging_configuration_id" {
  description = "The ID of the WAF logging configuration"
  value       = var.waf.logging.enabled && var.waf.create_waf ? aws_wafv2_web_acl_logging_configuration.main[0].id : null
}

output "log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = var.waf.logging.create_log_group ? aws_cloudwatch_log_group.waf_log_group[0].name : null
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = var.waf.logging.create_log_group ? aws_cloudwatch_log_group.waf_log_group[0].arn : null
}

#--------------------------------------------------------------------
# Comprehensive Module Outputs
#--------------------------------------------------------------------
output "waf_summary" {
  description = "Summary of the WAF configuration"
  value = var.waf.create_waf ? {
    web_acl_id          = aws_wafv2_web_acl.main[0].id
    web_acl_arn         = aws_wafv2_web_acl.main[0].arn
    web_acl_name        = aws_wafv2_web_acl.main[0].name
    web_acl_capacity    = aws_wafv2_web_acl.main[0].capacity
    scope               = aws_wafv2_web_acl.main[0].scope
    default_action      = var.waf.default_action
    managed_rules_count = length(var.waf.managed_rule_groups)
    custom_rules_count  = length(var.waf.custom_rules)
    json_rules_count    = length(local.json_rules)
    total_custom_rules  = length(local.all_custom_rules)
    json_files_loaded   = length(var.waf.rule_files)
    logging_enabled     = var.waf.logging.enabled
    alb_associated      = var.waf.association.associate_alb && var.waf.association.alb_arns != null
  } : null
}

#--------------------------------------------------------------------
# Legacy Compatibility Outputs (Deprecated)
#--------------------------------------------------------------------
output "waf_web_acl_id" {
  description = "The ID of the WAF Web ACL (deprecated - use web_acl_id instead)"
  value       = var.waf.create_waf ? aws_wafv2_web_acl.main[0].id : null
}

output "waf_web_acl_arn" {
  description = "The ARN of the WAF Web ACL (deprecated - use web_acl_arn instead)"
  value       = var.waf.create_waf ? aws_wafv2_web_acl.main[0].arn : null
}



