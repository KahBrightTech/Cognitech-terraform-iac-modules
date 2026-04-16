#--------------------------------------------------------------------
# Launch Template Outputs
#--------------------------------------------------------------------
output "launch_template_id" {
  description = "The ID of the launch template"
  value       = module.launch_template.id
}

output "launch_template_name" {
  description = "The name of the launch template"
  value       = module.launch_template.name
}

#--------------------------------------------------------------------
# ALB Outputs
#--------------------------------------------------------------------
output "alb_arn" {
  description = "The ARN of the ALB"
  value       = var.deploy_ansible.attach_to_elb && var.deploy_ansible.alb != null ? module.alb[0].arn : null
}

output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = var.deploy_ansible.attach_to_elb && var.deploy_ansible.alb != null ? module.alb[0].dns_name : null
}

output "alb_zone_id" {
  description = "The zone ID of the ALB"
  value       = var.deploy_ansible.attach_to_elb && var.deploy_ansible.alb != null ? module.alb[0].zone_id : null
}

output "alb_name" {
  description = "The name of the ALB"
  value       = var.deploy_ansible.attach_to_elb && var.deploy_ansible.alb != null ? module.alb[0].name : null
}

#--------------------------------------------------------------------
# Target Group Outputs
#--------------------------------------------------------------------
output "target_group_arn" {
  description = "The ARN of the target group"
  value       = var.deploy_ansible.attach_to_elb && var.deploy_ansible.target_group != null ? module.target_group[0].target_group_arn : null
}

output "target_group_id" {
  description = "The ID of the target group"
  value       = var.deploy_ansible.attach_to_elb && var.deploy_ansible.target_group != null ? module.target_group[0].target_group_id : null
}

#--------------------------------------------------------------------
# ALB Listener Outputs
#--------------------------------------------------------------------
output "alb_listener_arn" {
  description = "The ARN of the ALB listener"
  value       = var.deploy_ansible.attach_to_elb && var.deploy_ansible.alb_listener != null ? module.alb_listener[0].alb_listener_arn : null
}

output "alb_listener_id" {
  description = "The ID of the ALB listener"
  value       = var.deploy_ansible.attach_to_elb && var.deploy_ansible.alb_listener != null ? module.alb_listener[0].alb_listener_id : null
}

#--------------------------------------------------------------------
# ALB Listener Rule Outputs
#--------------------------------------------------------------------
output "alb_listener_rules" {
  description = "The ALB listener rules"
  value       = var.deploy_ansible.attach_to_elb && var.deploy_ansible.alb_listener_rule != null ? module.alb_listener_rule[0].alb_listener_rules : null
}

#--------------------------------------------------------------------
# Auto Scaling Group Outputs
#--------------------------------------------------------------------
output "asg_name" {
  description = "The name of the Auto Scaling group"
  value       = module.asg.name
}

output "asg_arn" {
  description = "The ARN of the Auto Scaling group"
  value       = module.asg.arn
}

output "asg_id" {
  description = "The ID of the Auto Scaling group"
  value       = module.asg.id
}

