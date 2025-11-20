#--------------------------------------------------------------------
# WAF Rule Group Outputs
#--------------------------------------------------------------------
output "rule_group_id" {
  description = "ID of the rule group created"
  value       = local.rule_group != null ? aws_wafv2_rule_group.rule_group[0].id : null
}

output "rule_group_arn" {
  description = "ARN of the rule group created"
  value       = local.rule_group != null ? aws_wafv2_rule_group.rule_group[0].arn : null
}

output "rule_group_name" {
  description = "Name of the rule group created"
  value       = local.rule_group != null ? aws_wafv2_rule_group.rule_group[0].name : null
}

output "rule_group_capacity" {
  description = "Capacity of the rule group created"
  value       = local.rule_group != null ? aws_wafv2_rule_group.rule_group[0].capacity : null
}

#--------------------------------------------------------------------
# Summary Output
#--------------------------------------------------------------------
output "rule_group_summary" {
  description = "Summary of rule group configuration"
  value = local.rule_group != null ? {
    rule_group_created = length(aws_wafv2_rule_group.rule_group) > 0
    json_files_loaded  = var.rule_group != null ? length(var.rule_group.rule_group_files) : 0
    scope              = var.scope
    capacity_used      = local.rule_group.capacity
    rules_count        = length(local.rule_group.rules)
    name               = local.rule_group.name
  } : null
}



