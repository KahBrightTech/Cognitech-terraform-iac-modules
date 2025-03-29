output "security_group_id" {
  description = "The security group id beking created"
  value       = length(aws_security_group.security_group_rules) > 0 ? aws_security_group_rules.security_group_rules[0].security_group_id : null

}

output "security_group_rule_id" {
  description = "The security group rule id"
  value       = length(aws_security_group_rules.security_group_rules) > 0 ? aws_security_group_rules.security_group_rules[0].id : null

}

output "security_group_rule_type" {
  description = "The type of the security group rule (ingress/egress)"
  value       = length(aws_security_group_rules.security_group_rules) > 0 ? aws_security_group_rules.security_group_rules[0].type : null

}

output "security_group_rule_protocol" {
  description = "The protocol of the security group rule"
  value       = length(aws_security_group_rules.security_group_rules) > 0 ? aws_security_group_rules.security_group_rules[0].protocol : null

}

output "security_group_rule_from_port" {
  description = "The starting port of the security group rule"
  value       = length(aws_security_group_rules.security_group_rules) > 0 ? aws_security_group_rules.security_group_rules[0].from_port : null

}

output "security_group_rule_to_port" {
  description = "The ending port of the security group rule"
  value       = length(aws_security_group_rules.security_group_rules) > 0 ? aws_security_group_rules.security_group_rules[0].to_port : null

}

output "security_group_rule_cidr_blocks" {
  description = "The CIDR blocks associated with the security group rule"
  value       = length(aws_security_group_rules.security_group_rules) > 0 ? aws_security_group_rules.security_group_rules[0].cidr_blocks : null

}
