# KMS Key Alias
resource "aws_kms_alias" "backup_key_alias" {
  name          = "alias/cmk/dailybackup"
  target_key_id = aws_kms_key.backup_key.key_id
}

# Backup Vault
resource "aws_backup_vault" "backup_vault" {
  name        = "${data.aws_ssm_parameter.account.value}-${var.app_name}-backup-vault"
  kms_key_arn = aws_kms_key.backup_key.arn
}

# IAM Role for Backup
resource "aws_iam_role" "backup_role" {
  name = "${var.app_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "backup.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  ]
}

# Backup Plan
resource "aws_backup_plan" "daily_backup_plan" {
  name = "${data.aws_ssm_parameter.account.value}-${var.app_name}-backup-plan"

  rule {
    rule_name         = "daily-backups"
    target_vault_name = aws_backup_vault.backup_vault.name
    schedule          = "cron(0 * * * ? *)"
    start_window      = 60
    completion_window = 120

    lifecycle {
      delete_after = 7
    }
  }
}

# Backup Selection
resource "aws_backup_selection" "daily_backup_selection" {
  name         = "${data.aws_ssm_parameter.account.value}-${var.app_name}-backup-tags"
  iam_role_arn = aws_iam_role.backup_role.arn
  plan_id      = aws_backup_plan.daily_backup_plan.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "backup"
    value = "${data.aws_region.current.name}-daily"
  }
}
