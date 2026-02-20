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
# Launch Template Outputs
#--------------------------------------------------------------------
output "launch_template_ids" {
  description = "Map of launch template IDs keyed by template key"
  value       = { for k, v in module.launch_template : k => v.id }
}

output "launch_template_arns" {
  description = "Map of launch template ARNs keyed by template key"
  value       = { for k, v in module.launch_template : k => v.arn }
}

output "launch_template_names" {
  description = "Map of launch template names keyed by template key"
  value       = { for k, v in module.launch_template : k => v.name }
}

#--------------------------------------------------------------------
# Auto Scaling Group Outputs
#--------------------------------------------------------------------
output "autoscaling_group_ids" {
  description = "Map of Auto Scaling Group IDs keyed by ASG name"
  value       = { for k, v in module.autoscaling_group : k => v.id }
}

output "autoscaling_group_arns" {
  description = "Map of Auto Scaling Group ARNs keyed by ASG name"
  value       = { for k, v in module.autoscaling_group : k => v.arn }
}

output "autoscaling_group_names" {
  description = "Map of Auto Scaling Group names keyed by ASG name"
  value       = { for k, v in module.autoscaling_group : k => v.name }
}

#--------------------------------------------------------------------
# ECS Capacity Provider Outputs
#--------------------------------------------------------------------
output "capacity_provider_id" {
  description = "The ID of the ECS Capacity Provider"
  value       = var.ecs.ec2_autoscaling != null ? aws_ecs_capacity_provider.ecs_ec2[0].id : null
}

output "capacity_provider_arn" {
  description = "The ARN of the ECS Capacity Provider"
  value       = var.ecs.ec2_autoscaling != null ? aws_ecs_capacity_provider.ecs_ec2[0].arn : null
}

#--------------------------------------------------------------------
# Auto Scaling Policy Outputs
#--------------------------------------------------------------------
output "scale_up_policy_arn" {
  description = "The ARN of the scale up policy"
  value       = var.ecs.ec2_autoscaling != null && var.ecs.ec2_autoscaling.scaling_policies != null ? aws_autoscaling_policy.ecs_scale_up[0].arn : null
}

output "scale_down_policy_arn" {
  description = "The ARN of the scale down policy"
  value       = var.ecs.ec2_autoscaling != null && var.ecs.ec2_autoscaling.scaling_policies != null ? aws_autoscaling_policy.ecs_scale_down[0].arn : null
}