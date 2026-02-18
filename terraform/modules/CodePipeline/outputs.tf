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
output "ecs_task_definition_arn" {
  description = "The ARN of the ECS task definition"
  value       = var.ecs.task_definition != null ? aws_ecs_task_definition.ecs[0].arn : null
}

output "ecs_task_definition_family" {
  description = "The family of the ECS task definition"
  value       = var.ecs.task_definition != null ? aws_ecs_task_definition.ecs[0].family : null
}

output "ecs_task_definition_revision" {
  description = "The revision of the ECS task definition"
  value       = var.ecs.task_definition != null ? aws_ecs_task_definition.ecs[0].revision : null
}

output "ecs_task_definition_arn_without_revision" {
  description = "The ARN of the ECS task definition without revision"
  value       = var.ecs.task_definition != null ? aws_ecs_task_definition.ecs[0].arn_without_revision : null
}

#--------------------------------------------------------------------
# ECS Service Outputs
#--------------------------------------------------------------------
output "ecs_service_id" {
  description = "The ID of the ECS service"
  value       = var.ecs.service != null ? aws_ecs_service.ecs[0].id : null
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = var.ecs.service != null ? aws_ecs_service.ecs[0].name : null
}

output "ecs_service_cluster" {
  description = "The cluster of the ECS service"
  value       = var.ecs.service != null ? aws_ecs_service.ecs[0].cluster : null
}

output "ecs_service_desired_count" {
  description = "The desired count of the ECS service"
  value       = var.ecs.service != null ? aws_ecs_service.ecs[0].desired_count : null
}

#--------------------------------------------------------------------
# Load Balancer Outputs
#--------------------------------------------------------------------
output "load_balancer_id" {
  description = "The ID of the load balancer"
  value       = var.load_balancer != null ? aws_lb.ecs[0].id : null
}

output "load_balancer_arn" {
  description = "The ARN of the load balancer"
  value       = var.load_balancer != null ? aws_lb.ecs[0].arn : null
}

output "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  value       = var.load_balancer != null ? aws_lb.ecs[0].dns_name : null
}

output "load_balancer_zone_id" {
  description = "The zone ID of the load balancer"
  value       = var.load_balancer != null ? aws_lb.ecs[0].zone_id : null
}

#--------------------------------------------------------------------
# Target Group Outputs
#--------------------------------------------------------------------
output "target_group_id" {
  description = "The ID of the target group"
  value       = var.target_group != null ? aws_lb_target_group.ecs[0].id : null
}

output "target_group_arn" {
  description = "The ARN of the target group"
  value       = var.target_group != null ? aws_lb_target_group.ecs[0].arn : null
}

output "target_group_name" {
  description = "The name of the target group"
  value       = var.target_group != null ? aws_lb_target_group.ecs[0].name : null
}

#--------------------------------------------------------------------
# Load Balancer Listener Outputs
#--------------------------------------------------------------------
output "lb_listener_id" {
  description = "The ID of the load balancer listener"
  value       = var.lb_listener != null ? aws_lb_listener.ecs[0].id : null
}

output "lb_listener_arn" {
  description = "The ARN of the load balancer listener"
  value       = var.lb_listener != null ? aws_lb_listener.ecs[0].arn : null
}

#--------------------------------------------------------------------
# EC2 Auto Scaling Outputs
#--------------------------------------------------------------------
output "launch_template_id" {
  description = "The ID of the launch template"
  value       = var.ec2_autoscaling != null ? aws_launch_template.ecs_ec2[0].id : null
}

output "launch_template_arn" {
  description = "The ARN of the launch template"
  value       = var.ec2_autoscaling != null ? aws_launch_template.ecs_ec2[0].arn : null
}

output "launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = var.ec2_autoscaling != null ? aws_launch_template.ecs_ec2[0].latest_version : null
}

output "autoscaling_group_id" {
  description = "The ID of the Auto Scaling Group"
  value       = var.ec2_autoscaling != null ? aws_autoscaling_group.ecs_ec2[0].id : null
}

output "autoscaling_group_arn" {
  description = "The ARN of the Auto Scaling Group"
  value       = var.ec2_autoscaling != null ? aws_autoscaling_group.ecs_ec2[0].arn : null
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = var.ec2_autoscaling != null ? aws_autoscaling_group.ecs_ec2[0].name : null
}

output "capacity_provider_id" {
  description = "The ID of the ECS Capacity Provider"
  value       = var.ec2_autoscaling != null ? aws_ecs_capacity_provider.ecs_ec2[0].id : null
}

output "capacity_provider_arn" {
  description = "The ARN of the ECS Capacity Provider"
  value       = var.ec2_autoscaling != null ? aws_ecs_capacity_provider.ecs_ec2[0].arn : null
}

output "scale_up_policy_arn" {
  description = "The ARN of the scale up policy"
  value       = var.ec2_autoscaling != null && var.ec2_autoscaling.scaling_policies != null ? aws_autoscaling_policy.ecs_scale_up[0].arn : null
}

output "scale_down_policy_arn" {
  description = "The ARN of the scale down policy"
  value       = var.ec2_autoscaling != null && var.ec2_autoscaling.scaling_policies != null ? aws_autoscaling_policy.ecs_scale_down[0].arn : null
}
