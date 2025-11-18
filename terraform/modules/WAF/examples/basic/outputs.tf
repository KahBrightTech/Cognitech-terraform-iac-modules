output "waf_id" {
  description = "The ID of the WAF Web ACL"
  value       = module.basic_waf.web_acl_id
}

output "waf_arn" {
  description = "The ARN of the WAF Web ACL"
  value       = module.basic_waf.web_acl_arn
}

output "waf_name" {
  description = "The name of the WAF Web ACL"
  value       = module.basic_waf.web_acl_name
}

output "waf_capacity" {
  description = "The capacity of the WAF Web ACL"
  value       = module.basic_waf.web_acl_capacity
}

output "waf_summary" {
  description = "Summary of the WAF configuration"
  value       = module.basic_waf.waf_summary
}