#--------------------------------------------------------------------
# NLB Target Group Outputs
#--------------------------------------------------------------------
output "nlb_target_group_arn" {
  description = "The ARN of the NLB target group"
  value       = module.nlb_target_group.target_group_arn
}

output "nlb_target_group_id" {
  description = "The ID of the NLB target group"
  value       = module.nlb_target_group.target_group_id
}

output "nlb_attachments" {
  description = "The attachments of the NLB target group"
  value       = var.nlb.listener.target_group && var.nlb_listener.target_group.attachments != null ? module.nlb_target_group.attachments : []

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
