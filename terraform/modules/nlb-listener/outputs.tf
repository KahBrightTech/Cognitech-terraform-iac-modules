#--------------------------------------------------------------------
# NLB Target Group Outputs
#--------------------------------------------------------------------
output "nlb_target_group_arn" {
  description = "The ARN of the NLB target group"
  value       = var.nlb_listener.action == "forward" && var.nlb_listener.target_group != null && length(module.nlb_target_group) > 0 ? module.nlb_target_group[0].target_group_arn : null
}

output "nlb_target_group_id" {
  description = "The ID of the NLB target group"
  value       = var.nlb_listener.action == "forward" && var.nlb_listener.target_group != null && length(module.nlb_target_group) > 0 ? module.nlb_target_group[0].target_group_id : null
}

#--------------------------------------------------------------------
# NLB Listener Outputs
#--------------------------------------------------------------------
output "nlb_listener_arn" {
  description = "The ARN of the NLB listener"
  value       = aws_lb_listener.nlb_listener.arn
}

output "nlb_listener_id" {
  description = "The ID of the NLB listener"
  value       = aws_lb_listener.nlb_listener.id
}
