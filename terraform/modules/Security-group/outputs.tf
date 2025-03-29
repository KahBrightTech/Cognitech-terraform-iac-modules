output "security_group_id" {
  description = "The security group id"
  value       = aws_security_group.security_group.id
}

output "security_group_arn" {
  description = "The security group ARN"
  value       = aws_security_group.security_group.arn

}
