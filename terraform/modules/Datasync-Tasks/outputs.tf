#--------------------------------------------------------------------
# DataSync Task Outputs
#--------------------------------------------------------------------

output "datasync_task_arn" {
  description = "ARN of the DataSync task"
  value       = var.datasync.task != null ? aws_datasync_task.task[0].arn : null
}

output "datasync_task_id" {
  description = "ID of the DataSync task"
  value       = var.datasync.task != null ? aws_datasync_task.task[0].id : null
}

#--------------------------------------------------------------------
# CloudWatch Log Group Outputs
#--------------------------------------------------------------------

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for DataSync"
  value       = var.datasync.create_cloudwatch_log_group ? aws_cloudwatch_log_group.datasync[0].arn : null
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for DataSync"
  value       = var.datasync.create_cloudwatch_log_group ? aws_cloudwatch_log_group.datasync[0].name : null
}

output "cloudwatch_log_resource_policy_name" {
  description = "Name of the CloudWatch log resource policy for DataSync"
  value       = var.datasync.create_cloudwatch_log_group ? aws_cloudwatch_log_resource_policy.datasync[0].policy_name : null
}

#--------------------------------------------------------------------
# Troubleshooting Outputs
#--------------------------------------------------------------------

output "datasync_task_log_level" {
  description = "Log level configured for the DataSync task (for troubleshooting)"
  value       = var.datasync.task != null && var.datasync.task.options != null ? var.datasync.task.options.log_level : "Not specified - will default based on CloudWatch configuration"
}

output "datasync_task_cloudwatch_config" {
  description = "CloudWatch configuration status for troubleshooting"
  value = {
    log_group_created      = var.datasync.create_cloudwatch_log_group
    log_group_arn_provided = var.datasync.task != null ? var.datasync.task.cloudwatch_log_group_arn != null : false
    logging_enabled        = var.datasync.create_cloudwatch_log_group || (var.datasync.task != null ? var.datasync.task.cloudwatch_log_group_arn != null : false)
  }
}