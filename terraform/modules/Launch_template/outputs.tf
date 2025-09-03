output "id" {
  description = "The ID of the launch template"
  value       = aws_launch_template.main.id
}

output "arn" {
  description = "The ARN of the launch template"
  value       = aws_launch_template.main.arn
}

output "name" {
  description = "The name of the launch template"
  value       = aws_launch_template.main.name
}
