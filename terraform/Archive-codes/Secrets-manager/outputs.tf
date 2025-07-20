output "arn" {
  description = "The ARN of the created secret"
  value       = length(aws_secretsmanager_secret.secret) > 0 ? aws_secretsmanager_secret.secret[0].arn : null
}

output "id" {
  description = "The ID of the created secret"
  value       = length(aws_secretsmanager_secret.secret) > 0 ? aws_secretsmanager_secret.secret[0].id : null
}

output "name" {
  description = "The name of the created secret"
  value       = length(aws_secretsmanager_secret.secret) > 0 ? aws_secretsmanager_secret.secret[0].name : null
}

