
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
  kms_key_arn = var.backup.kms_key_arn
  tags = merge(var.common.tags, {
    Name = "${var.common.account_name_abr}-${var.common.region_prefix}-${var.backup.name}-vault"
  })
}

#--------------------------------------------------------------------
# AWS Backup Plan
#--------------------------------------------------------------------
resource "aws_backup_plan" "plan" {
  name = var.backup.plan.name != null ? var.backup.plan.name : "${var.common.account_name_abr}-${var.common.region_prefix}-backup-plan"

  rule {
    rule_name         = var.backup.plan.rule_name != null ? var.backup.plan.rule_name : "${var.common.account_name_abr}-${var.common.region_prefix}-backup-rule"
    target_vault_name = aws_backup_vault.backup_vault.name
    schedule          = var.backup.plan.schedule
    start_window      = var.backup.plan.start_window
    completion_window = var.backup.plan.completion_window

    lifecycle {
      delete_after = var.backup.plan.lifecycle != null ? var.backup.plan.lifecycle.delete_after : null
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
