
#--------------------------------------------------------------------
# AWS Backup vault
#--------------------------------------------------------------------
resource "aws_backup_vault" "backup_vault" {
  name        = var.backup.name
  kms_key_arn = var.backup.kms_key_arn
  tags = merge(var.common.tags, {
    Name = "${var.common.account_name_abr}-${var.common.region_prefix}-${var.backup.name}-vault"
  })
}

#--------------------------------------------------------------------
# AWS Backup Role
#--------------------------------------------------------------------
resource "aws_iam_role" "backup_role" {
  name = var.backup.role_name != null ? var.backup.role_name : "${var.common.account_name_abr}-${var.common.region_prefix}-backup-role"
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

  tags = merge(var.common.tags, {
    Name = var.backup.role_name != null ? var.backup.role_name : "${var.common.account_name_abr}-${var.common.region_prefix}-backup-role"
  })
}

#--------------------------------------------------------------------
# AWS Backup Role Policy Attachment
#--------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
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
