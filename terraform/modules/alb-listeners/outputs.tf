#--------------------------------------------------------------------
# ALB Target Group Outputs
#--------------------------------------------------------------------
output "alb_target_group_arn" {
  description = "The ARN of the ALB target group"
  value = var.alb_listener.action == "forward" ? (
    length(module.alb_target_group) > 0
    ? module.alb_target_group[0].target_group_arn
    : var.alb_listener.target_group_arn
  ) : null
}

output "alb_target_group_id" {
  description = "The ID of the ALB target group"
  value = var.alb_listener.action == "forward" ? (
    length(module.alb_target_group) > 0
    ? module.alb_target_group[0].target_group_id
    : var.alb_listener.target_group_arn
  ) : null
}

output "alb_tg_attachments" {
  description = "The attachments of the ALB target group"
  value = var.alb_listener.action == "forward" && length(module.alb_target_group) > 0 ? (
    var.alb_listener.target_group != null && var.alb_listener.target_group.attachments != null
    ? module.alb_target_group[0].target_group_attachments
    : null
  ) : null
}

#--------------------------------------------------------------------
# ALB Listener Outputs
#--------------------------------------------------------------------
output "alb_listener_arn" {
  description = "The ARN of the ALB listener"
  value       = aws_lb_listener.alb_listener.arn
}

output "alb_listener_id" {
  description = "The ID of the ALB listener"
  value       = aws_lb_listener.alb_listener.id
}