#--------------------------------------------------------------------
# ECS Cluster Outputs
#--------------------------------------------------------------------
output "ecs_cluster_id" {
  description = "The ID of the ECS cluster"
  value       = aws_ecs_cluster.ecs.id
}

output "ecs_cluster_arn" {
  description = "The ARN of the ECS cluster"
  value       = aws_ecs_cluster.ecs.arn
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = aws_ecs_cluster.ecs.name
}

#--------------------------------------------------------------------
# ECS Task Definition Outputs
#--------------------------------------------------------------------
output "ecs_task_definition_arns" {
  description = "Map of task definition ARNs keyed by family name"
  value       = { for k, v in aws_ecs_task_definition.ecs : k => v.arn }
}

output "ecs_task_definition_families" {
  description = "Map of task definition families keyed by family name"
  value       = { for k, v in aws_ecs_task_definition.ecs : k => v.family }
}

output "ecs_task_definition_revisions" {
  description = "Map of task definition revisions keyed by family name"
  value       = { for k, v in aws_ecs_task_definition.ecs : k => v.revision }
}

output "ecs_task_definition_arns_without_revision" {
  description = "Map of task definition ARNs without revision keyed by family name"
  value       = { for k, v in aws_ecs_task_definition.ecs : k => v.arn_without_revision }
}

#--------------------------------------------------------------------
# ECS Service Outputs
#--------------------------------------------------------------------
output "ecs_service_ids" {
  description = "Map of ECS service IDs keyed by service name"
  value       = { for k, v in aws_ecs_service.ecs : k => v.id }
}

output "ecs_service_names" {
  description = "Map of ECS service names keyed by service name"
  value       = { for k, v in aws_ecs_service.ecs : k => v.name }
}

output "ecs_service_clusters" {
  description = "Map of ECS service clusters keyed by service name"
  value       = { for k, v in aws_ecs_service.ecs : k => v.cluster }
}

output "ecs_service_desired_counts" {
  description = "Map of ECS service desired counts keyed by service name"
  value       = { for k, v in aws_ecs_service.ecs : k => v.desired_count }
}

#--------------------------------------------------------------------
# EC2 Auto Scaling Outputs
#--------------------------------------------------------------------
output "launch_template_id" {
  description = "The ID of the launch template"
  value       = var.ecs.ec2_autoscaling != null ? aws_launch_template.ecs_ec2[0].id : null
}

output "launch_template_arn" {
  description = "The ARN of the launch template"
  value       = var.ecs.ec2_autoscaling != null ? aws_launch_template.ecs_ec2[0].arn : null
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = var.ecs.ec2_autoscaling != null ? aws_launch_template.ecs_ec2[0].latest_version : null
}

output "autoscaling_group_id" {
  description = "The ID of the Auto Scaling Group"
  value       = var.ecs.ec2_autoscaling != null ? aws_autoscaling_group.ecs_ec2[0].id : null
}

output "autoscaling_group_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = var.ecs.ec2_autoscaling != null ? aws_autoscaling_group.ecs_ec2[0].arn : null
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = var.ecs.ec2_autoscaling != null ? aws_autoscaling_group.ecs_ec2[0].name : null
}

output "capacity_provider_id" {
  description = "The ID of the ECS Capacity Provider"
  value       = var.ecs.ec2_autoscaling != null ? aws_ecs_capacity_provider.ecs_ec2[0].id : null
}

output "capacity_provider_arn" {
  description = "The ARN of the ECS Capacity Provider"
  value       = var.ecs.ec2_autoscaling != null ? aws_ecs_capacity_provider.ecs_ec2[0].arn : null
}

output "scale_up_policy_arn" {
  description = "The ARN of the scale up policy"
  value       = var.ecs.ec2_autoscaling != null && var.ecs.ec2_autoscaling.scaling_policies != null ? aws_autoscaling_policy.ecs_scale_up[0].arn : null
}

output "scale_down_policy_arn" {
  description = "The ARN of the scale down policy"
  value       = var.ecs.ec2_autoscaling != null && var.ecs.ec2_autoscaling.scaling_policies != null ? aws_autoscaling_policy.ecs_scale_down[0].arn : null
}
