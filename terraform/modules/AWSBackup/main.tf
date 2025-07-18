
#--------------------------------------------------------------------
# Data Sources
#--------------------------------------------------------------------
data "aws_region" "current" {}

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

#--------------------------------------------------------------------
# AWS Backup vault
#--------------------------------------------------------------------
resource "aws_backup_vault" "backup_vault" {
  name        = var.backup.name
  kms_key_arn = var.backup.kms_key_id
  tags = merge(var.common.tags, {
    Name = "${var.common.account_name_abr}-${var.common.region_prefix}-${var.backup.name}-vault"
  })
}

#--------------------------------------------------------------------
# AWS Backup Plan
#--------------------------------------------------------------------
resource "aws_backup_plan" "plan" {
  name = var.backup.plan.name != null ? var.backup.plan.name : "${var.common.account_name_abr}-${var.common.region_prefix}-backup-plan"

  dynamic "rule" {
    for_each = var.backup.plan.rules
    content {
      rule_name         = rule.value.rule_name != null ? rule.value.rule_name : "${var.common.account_name_abr}-${var.common.region_prefix}-backup-rule"
      target_vault_name = aws_backup_vault.backup_vault.name
      schedule          = rule.value.schedule
      start_window      = rule.value.start_window
      completion_window = rule.value.completion_window

      dynamic "lifecycle" {
        for_each = rule.value.lifecycle != null && (rule.value.lifecycle.delete_after_days != null || rule.value.lifecycle.cold_storage_after_days != null) ? [rule.value.lifecycle] : []
        content {
          delete_after       = lifecycle.value.delete_after_days
          cold_storage_after = lifecycle.value.cold_storage_after_days
        }
      }
    }
  }
}

#--------------------------------------------------------------------
# AWS Backup Selection
#--------------------------------------------------------------------
resource "aws_backup_selection" "selection" {
  count = var.backup.plan.selection != null ? 1 : 0

  name         = var.backup.plan.selection.selection_name != null ? var.backup.plan.selection.selection_name : "${var.common.account_name_abr}-${var.common.region_prefix}-backup-selection"
  iam_role_arn = aws_iam_role.backup_role.arn
  plan_id      = aws_backup_plan.plan.id

  # Use variablized selection tags if provided, otherwise use default
  dynamic "selection_tag" {
    for_each = length(var.backup.plan.selection.selection_tags) > 0 ? var.backup.plan.selection.selection_tags : [
    ]
    content {
      type  = selection_tag.value.type
      key   = selection_tag.value.key
      value = selection_tag.value.value
    }
  }

  # Optional: Include specific resources if provided
  resources = var.backup.plan.selection.resources != null ? var.backup.plan.selection.resources : []
}
