
output "iam_uer_arn" {
  description = "The ARN of the IAM User"
  value       = aws_iam_user.iam_user.arn
}

output "iam_user_name" {
  description = "The name of the IAM User"
  value       = aws_iam_user.iam_user.name
}

output "secrets_manager_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing the IAM user credentials"
  value       = var.iam_user.create_access_key ? aws_secretsmanager_secret.iam_user_credentials[0].arn : null
}

output "secrets_manager_secret_name" {
  description = "The name of the Secrets Manager secret containing the IAM user credentials"
  value       = var.iam_user.create_access_key ? aws_secretsmanager_secret.iam_user_credentials[0].name : null
}

output "access_key_id" {
  description = "The access key ID (also available in Secrets Manager)"
  value       = var.iam_user.create_access_key ? data.external.create_access_key.result["access_key_id"] : null
  sensitive   = true
}

output "iam_groups" {
  description = "The names of the IAM groups created"
  value       = [for group in aws_iam_group.iam_groups : group.name]
}

output "group_policy_arns" {
  description = "The ARNs of the group policies created"
  value       = [for policy in aws_iam_policy.group_policies : policy.arn]
}
