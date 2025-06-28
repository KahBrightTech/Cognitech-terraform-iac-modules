#--------------------------------------------------------------------
# Outputs for ec2 key pairs
#--------------------------------------------------------------------
output "name" {
  description = "The name of the generated key pair"
  value       = aws_key_pair.generated_key.key_name
}

output "secret_arn" {
  description = "The ARN of the created Secrets Manager secret (if created)"
  value       = var.create_secret ? aws_secretsmanager_secret.private_key_secret[0].arn : null
}
