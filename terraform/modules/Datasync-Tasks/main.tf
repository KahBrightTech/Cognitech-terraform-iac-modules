#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#--------------------------------------------------------------------
# CloudWatch Log Group (Optional)
# Note: DataSync requires resource-based policy to write to CloudWatch Logs
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
# CloudWatch Log Group Resource Policy for DataSync
#--------------------------------------------------------------------
data "aws_iam_policy_document" "datasync_log_group_policy" {
  count = var.datasync.create_cloudwatch_log_group ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.datasync[0].arn}:*"
    ]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:datasync:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/*"
      ]
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "datasync" {
  count           = var.datasync.create_cloudwatch_log_group ? 1 : 0
  policy_name     = "${var.common.account_name}-${var.common.region_prefix}-datasync-logs-policy"
  policy_document = data.aws_iam_policy_document.datasync_log_group_policy[0].json
}

#--------------------------------------------------------------------
# DataSync Task
#--------------------------------------------------------------------
resource "aws_datasync_task" "task" {
  count = var.datasync.task != null && var.datasync.task.schedule_expression != null ? 1 : 0

  name                     = var.datasync.task.name
  source_location_arn      = var.datasync.task.source_location_arn
  destination_location_arn = var.datasync.task.destination_location_arn
  cloudwatch_log_group_arn = var.datasync.task.cloudwatch_log_group_arn != null ? var.datasync.task.cloudwatch_log_group_arn : (var.datasync.create_cloudwatch_log_group ? aws_cloudwatch_log_group.datasync[0].arn : null)

  dynamic "options" {
    for_each = var.datasync.task.options != null ? [var.datasync.task.options] : [{}]
    content {
      atime                          = options.value.atime
      bytes_per_second               = options.value.bytes_per_second
      gid                            = options.value.gid
      log_level                      = options.value.log_level != null ? options.value.log_level : (var.datasync.create_cloudwatch_log_group || var.datasync.task.cloudwatch_log_group_arn != null ? "TRANSFER" : "OFF")
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
  schedule {
    schedule_expression = var.datasync.task.schedule_expression
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.task.name}-task"
  })
}

