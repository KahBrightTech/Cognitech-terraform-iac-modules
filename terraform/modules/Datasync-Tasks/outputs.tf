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