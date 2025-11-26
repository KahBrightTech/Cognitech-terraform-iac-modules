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
# Summary Output
#--------------------------------------------------------------------
output "waf_summary" {
  description = "Summary of the WAF configuration"
  value = {
    web_acl_id            = aws_wafv2_web_acl.main.id
    web_acl_arn           = aws_wafv2_web_acl.main.arn
    web_acl_name          = aws_wafv2_web_acl.main.name
    web_acl_capacity      = aws_wafv2_web_acl.main.capacity
    scope                 = aws_wafv2_web_acl.main.scope
    default_action        = var.waf.default_action
    rule_group_refs_count = var.waf.rule_group_references != null ? length(var.waf.rule_group_references) : 0
    custom_rules_count    = var.waf.custom_rules != null ? length(var.waf.custom_rules) : 0
    json_file_loaded      = var.waf.rule_file != null ? true : false
  }
}





