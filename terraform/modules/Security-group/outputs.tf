output "security_group_id" {
  description = "The security group id"
  value       = length(aws_security_group.main) > 0 ? aws_security_group.main[0].id : null
}

output "security_group_arn" {
  description = "The security group ARN"
  value       = length(aws_security_group.main) > 0 ? aws_security_group.main[0].arn : null

}
