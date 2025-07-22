#--------------------------------------------------------------------
# ALB Target Group Outputs
#--------------------------------------------------------------------
output "alb_target_group_arn" {
  description = "The ARN of the ALB target group"
  value       = var.alb_listener.action == "forward" ? module.alb_target_group.target_group_arn : null
}

output "alb_target_group_id" {
  description = "The ID of the ALB target group"
  value       = var.alb_listener.action == "forward" ? module.alb_target_group.target_group_id : null

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


