output "arn" {
  description = "AWS secrets manager ARN"
  value       = aws_secretsmanager_secret.secret.arn
}

output "id" {
  description = "AWS secrets manager ID"
  value       = aws_secretsmanager_secret.secret.id
}

output "name" {
  description = "AWS secrets manager name"
  value       = aws_secretsmanager_secret.secret.name
}
