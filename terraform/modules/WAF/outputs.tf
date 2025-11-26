#--------------------------------------------------------------------
# AWS WAF Web ACL Outputs
#--------------------------------------------------------------------
output "web_acl_id" {
  description = "The ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.id
}

output "web_acl_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "web_acl_name" {
  description = "The name of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.name
}

output "web_acl_capacity" {
  description = "The capacity of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.capacity
}

output "web_acl_description" {
  description = "The description of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.description
}

output "web_acl_scope" {
  description = "The scope of the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.scope
}

output "web_acl_tags" {
  description = "The tags applied to the WAF Web ACL"
  value       = aws_wafv2_web_acl.main.tags_all
}

#--------------------------------------------------------------------
# Association Outputs
#--------------------------------------------------------------------
output "web_acl_association_id" {
  description = "The ID of the WAF Web ACL association"
  value       = var.waf.association != null && var.waf.association.associate_alb && var.waf.association.alb_arns != null ? [for k, v in aws_wafv2_web_acl_association.main : v.id] : []
}

#--------------------------------------------------------------------
# Logging Outputs
#--------------------------------------------------------------------
output "logging_configuration_id" {
  description = "The ID of the WAF logging configuration"
  value       = var.waf.logging != null && var.waf.logging.enabled ? aws_wafv2_web_acl_logging_configuration.main[0].id : null
}

output "log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = var.waf.logging != null && var.waf.logging.create_log_group ? aws_cloudwatch_log_group.waf_log_group[0].name : null
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group"
  value       = var.waf.logging != null && var.waf.logging.create_log_group ? aws_cloudwatch_log_group.waf_log_group[0].arn : null
}

#--------------------------------------------------------------------
# Comprehensive Module Outputs
#--------------------------------------------------------------------
output "waf_summary" {
  description = "Summary of the WAF configuration"
  value = {
    web_acl_id             = aws_wafv2_web_acl.main.id
    web_acl_arn            = aws_wafv2_web_acl.main.arn
    web_acl_name           = aws_wafv2_web_acl.main.name
    web_acl_capacity       = aws_wafv2_web_acl.main.capacity
    scope                  = aws_wafv2_web_acl.main.scope
    default_action         = var.waf.default_action
    rule_group_refs_count  = var.waf.rule_group_references != null ? length(var.waf.rule_group_references) : 0
    custom_rules_count     = var.waf.custom_rules != null ? length(var.waf.custom_rules) : 0
    json_file_loaded       = var.waf.rule_file != null ? 1 : 0
    logging_enabled        = var.waf.logging != null ? var.waf.logging.enabled : false
    alb_associated         = var.waf.association != null && var.waf.association.associate_alb && var.waf.association.alb_arns != null
    alb_associations_count = var.waf.association != null && var.waf.association.associate_alb && var.waf.association.alb_arns != null ? length(var.waf.association.alb_arns) : 0
  }
}

#--------------------------------------------------------------------
# Legacy Compatibility Outputs (Deprecated)
#--------------------------------------------------------------------
output "waf_web_acl_id" {
  description = "The ID of the WAF Web ACL (deprecated - use web_acl_id instead)"
  value       = aws_wafv2_web_acl.main.id
}

output "waf_web_acl_arn" {
  description = "The ARN of the WAF Web ACL (deprecated - use web_acl_arn instead)"
  value       = aws_wafv2_web_acl.main.arn
}



