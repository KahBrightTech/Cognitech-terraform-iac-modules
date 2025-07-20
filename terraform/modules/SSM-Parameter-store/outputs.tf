output "name" {
  description = "The name of the SSM Parameter"
  value       = aws_ssm_parameter.parameter.name
}
output "arn" {
  description = "The ARN of the SSM Parameter"
  value       = aws_ssm_parameter.parameter.arn
}
output "id" {
  description = "The ID of the SSM Parameter"
  value       = aws_ssm_parameter.parameter.id
}
output "version" {
  description = "The version of the SSM Parameter"
  value       = aws_ssm_parameter.parameter.version
}
output "type" {
  description = "The type of the SSM Parameter"
  value       = aws_ssm_parameter.parameter.type
}
