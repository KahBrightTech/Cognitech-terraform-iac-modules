#--------------------------------------------------------------------
# AWS Backup Outputs
#--------------------------------------------------------------------
output "backup_vault_arn" {
  description = "ARN of the backup vault"
  value       = aws_backup_vault.backup_vault.arn
}

output "backup_vault_name" {
  description = "Name of the backup vault"
  value       = aws_backup_vault.backup_vault.name
}

output "backup_plan_arn" {
  description = "ARN of the backup plan"
  value       = length(aws_backup_plan.plan) > 0 ? values(aws_backup_plan.plan)[0].arn : null
}

output "backup_plan_id" {
  description = "ID of the backup plan"
  value       = length(aws_backup_plan.plan) > 0 ? values(aws_backup_plan.plan)[0].id : null
}

output "backup_selection_id" {
  description = "ID of the backup selection"
  value       = length(aws_backup_selection.selection) > 0 ? values(aws_backup_selection.selection)[0].id : null
}

output "backup_role_arn" {
  description = "ARN of the backup service role"
  value       = aws_iam_role.backup_role.arn
}


