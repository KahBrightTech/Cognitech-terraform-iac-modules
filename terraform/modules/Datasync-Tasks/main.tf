#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
# Get stable role ARNs using sort() to ensure consistent ordering

#--------------------------------------------------------------------
# CloudWatch Log Group (Optional)
#--------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "datasync" {
  count             = var.datasync.create_cloudwatch_log_group ? 1 : 0
  name              = var.datasync.cloudwatch_log_group_name != null ? "/aws/datasync/${var.datasync.cloudwatch_log_group_name}" : null
  retention_in_days = var.datasync.cloudwatch_log_retention_days

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.cloudwatch_log_group_name}-log-group"
  })
}

#--------------------------------------------------------------------
# DataSync Task (Optional)
#--------------------------------------------------------------------

resource "aws_datasync_task" "task" {
  count = var.datasync.task != null ? 1 : 0

  name                     = var.datasync.task.name
  source_location_arn      = var.datasync.task.source_location_arn
  destination_location_arn = var.datasync.task.destination_location_arn
  cloudwatch_log_group_arn = var.datasync.task.cloudwatch_log_group_arn != null ? var.datasync.task.cloudwatch_log_group_arn : (var.datasync.create_cloudwatch_log_group ? aws_cloudwatch_log_group.datasync[0].arn : null)

  dynamic "options" {
    for_each = var.datasync.task.options != null ? [var.datasync.task.options] : []
    content {
      atime                          = options.value.atime
      bytes_per_second               = options.value.bytes_per_second
      gid                            = options.value.gid
      log_level                      = options.value.log_level
      mtime                          = options.value.mtime
      overwrite_mode                 = options.value.overwrite_mode
      posix_permissions              = options.value.posix_permissions
      preserve_deleted_files         = options.value.preserve_deleted_files
      preserve_devices               = options.value.preserve_devices
      security_descriptor_copy_flags = options.value.security_descriptor_copy_flags
      task_queueing                  = options.value.task_queueing
      transfer_mode                  = options.value.transfer_mode
      uid                            = options.value.uid
      verify_mode                    = options.value.verify_mode
    }
  }

  dynamic "excludes" {
    for_each = var.datasync.task.excludes != null ? var.datasync.task.excludes : []
    content {
      filter_type = excludes.value.filter_type
      value       = excludes.value.value
    }
  }

  dynamic "includes" {
    for_each = var.datasync.task.includes != null ? var.datasync.task.includes : []
    content {
      filter_type = includes.value.filter_type
      value       = includes.value.value
    }
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.task.name}-task"
  })
}

# DataSync Task Schedule (if specified)
resource "aws_cloudwatch_event_rule" "datasync_schedule" {
  count = var.datasync.task != null && var.datasync.task.schedule_expression != null ? 1 : 0

  name                = "${var.datasync.task.name}-schedule"
  description         = "Schedule for DataSync task ${var.datasync.task.name}"
  schedule_expression = var.datasync.task.schedule_expression

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.task.name}-schedule"
  })
}

resource "aws_cloudwatch_event_target" "datasync_target" {
  count     = var.datasync.task != null && var.datasync.task.schedule_expression != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.datasync_schedule[0].name
  target_id = "DataSyncTaskTarget"
  arn       = aws_datasync_task.task[0].arn

  role_arn = aws_iam_role.datasync_events_role[0].arn
}

# IAM role for CloudWatch Events to execute DataSync task
resource "aws_iam_role" "datasync_events_role" {
  count = var.datasync.task != null && var.datasync.task.schedule_expression != null ? 1 : 0

  name = "${var.datasync.task.name}-events-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.task.name}-event-role"
  })
}

resource "aws_iam_role_policy" "datasync_events_policy" {
  count = var.datasync.task != null && var.datasync.task.schedule_expression != null ? 1 : 0

  name = "${var.datasync.task.name}-events-policy"
  role = aws_iam_role.datasync_events_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "datasync:StartTaskExecution"
        ]
        Resource = aws_datasync_task.task[0].arn
      }
    ]
  })
}

#--------------------------------------------------------------------
# IAM Policy - Creates IAM policy for the specified IAM role
#--------------------------------------------------------------------

resource "aws_iam_policy" "policy" {
  count = var.datasync.create_iam_resources && var.datasync.iam_role != null ? 1 : 0

  name        = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.iam_role.policy.name}-policy"
  description = var.datasync.iam_role.policy.description
  path        = var.datasync.iam_role.policy.path
  policy = var.datasync.iam_role.policy.custom_policy ? jsonencode(jsondecode(replace(
    replace(
      replace(
        file(var.datasync.iam_role.policy.policy),
        "[[account_number]]", data.aws_caller_identity.current.account_id,
      ),
      "[[account_name_abr]]", var.common.account_name_abr
    ),
    "[[region]]", data.aws_region.current.id
  ))) : jsonencode(jsondecode(file(var.datasync.iam_role.policy.policy)))

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.iam_role.policy.name}-policy"
  })
}

#--------------------------------------------------------------------
# IAM Role - Creates IAM role with the specified policy
#--------------------------------------------------------------------
resource "aws_iam_role" "role" {
  count = var.datasync.create_iam_resources && var.datasync.iam_role != null ? 1 : 0

  name        = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.iam_role.name}-role"
  description = var.datasync.iam_role.description
  path        = var.datasync.iam_role.path
  assume_role_policy = var.datasync.iam_role.custom_assume_role_policy ? jsonencode(jsondecode(replace(
    replace(
      replace(
        file(var.datasync.iam_role.assume_role_policy),
        "[[account_number]]", data.aws_caller_identity.current.account_id
      ),
      "[[account_name_abr]]", var.common.account_name_abr
    ),
    "[[region]]", data.aws_region.current.id
  ))) : jsonencode(jsondecode(file(var.datasync.iam_role.assume_role_policy)))
  force_detach_policies = var.datasync.iam_role.force_detach_policies
  max_session_duration  = var.datasync.iam_role.max_session_duration
  permissions_boundary  = var.datasync.iam_role.permissions_boundary
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.iam_role.policy.name}-role"
  })
}

#--------------------------------------------------------------------
#Attach IAM Policy to Role
#--------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "policy_attachment" {
  count = var.datasync.create_iam_resources && var.datasync.iam_role != null && var.datasync.iam_role.policy != null ? 1 : 0

  role       = aws_iam_role.role[0].name
  policy_arn = aws_iam_policy.policy[0].arn
}

#--------------------------------------------------------------------
# Attach managed policies to Role (if provided)
#--------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "managed_policy_attachment" {
  for_each   = var.datasync.create_iam_resources && var.datasync.iam_role != null && var.datasync.iam_role.managed_policy_arns != null ? toset(var.datasync.iam_role.managed_policy_arns) : []
  role       = aws_iam_role.role[0].name
  policy_arn = each.value
}
