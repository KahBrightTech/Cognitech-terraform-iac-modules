#--------------------------------------------------------------------
# S3 Outputs
#--------------------------------------------------------------------
output "artifact_bucket_name" {
  description = "Name of the S3 bucket used for pipeline artifacts"
  value       = var.codepipeline != null ? aws_s3_bucket.artifacts[0].bucket : null
}

output "artifact_bucket_arn" {
  description = "ARN of the S3 bucket used for pipeline artifacts"
  value       = var.codepipeline != null ? aws_s3_bucket.artifacts[0].arn : null
}

#--------------------------------------------------------------------
# IAM Outputs
#--------------------------------------------------------------------
output "codepipeline_role_arn" {
  description = "ARN of the CodePipeline IAM role"
  value       = var.codepipeline != null ? aws_iam_role.codepipeline[0].arn : null
}

output "codedeploy_role_arn" {
  description = "ARN of the CodeDeploy IAM role"
  value       = var.codepipeline != null ? aws_iam_role.codedeploy[0].arn : null
}

output "eventbridge_role_arn" {
  description = "ARN of the EventBridge IAM role"
  value       = var.codepipeline != null ? aws_iam_role.eventbridge[0].arn : null
}

#--------------------------------------------------------------------
# CodePipeline Outputs
#--------------------------------------------------------------------
output "pipeline_arns" {
  description = "Map of pipeline names to their ARNs"
  value       = var.codepipeline != null ? { for k, v in aws_codepipeline.this : k => v.arn } : {}
}

output "pipeline_ids" {
  description = "Map of pipeline names to their IDs"
  value       = var.codepipeline != null ? { for k, v in aws_codepipeline.this : k => v.id } : {}
}

#--------------------------------------------------------------------
# CodeDeploy Outputs
#--------------------------------------------------------------------
output "codedeploy_app_names" {
  description = "Map of pipeline names to their CodeDeploy application names"
  value       = var.codepipeline != null ? { for k, v in aws_codedeploy_app.this : k => v.name } : {}
}

output "codedeploy_app_arns" {
  description = "Map of pipeline names to their CodeDeploy application ARNs"
  value       = var.codepipeline != null ? { for k, v in aws_codedeploy_app.this : k => v.arn } : {}
}

output "codedeploy_deployment_group_names" {
  description = "Map of pipeline names to their CodeDeploy deployment group names"
  value       = var.codepipeline != null ? { for k, v in aws_codedeploy_deployment_group.this : k => v.deployment_group_name } : {}
}

#--------------------------------------------------------------------
# EventBridge Outputs
#--------------------------------------------------------------------
output "eventbridge_rule_arns" {
  description = "Map of pipeline names to their EventBridge rule ARNs"
  value       = var.codepipeline != null ? { for k, v in aws_cloudwatch_event_rule.ecr_push : k => v.arn } : {}
}
