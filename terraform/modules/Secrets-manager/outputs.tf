output "arn" {
  description = "AWS secrets manager ARN"
  value       = aws_secretsmanager_secret.secret[count.index].arn
}

output "id" {
  description = "AWS secrets manager ID"
  value       = aws_secretsmanager_secret.secret[count.index].id
}

output "name" {
  description = "AWS secrets manager name"
  value       = aws_secretsmanager_secret.secret[count.index].name
}

