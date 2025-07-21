#--------------------------------------------------------------------
# Load Balancer Listeners Module
#--------------------------------------------------------------------
output "listener_arn" {
  description = "The ARN of the Load Balancer listener"
  value       = aws_lb_listener.listener.arn
}

output "listener_id" {
  description = "The ID of the Load Balancer listener"
  value       = aws_lb_listener.listener.id
}

output "listener_port" {
  description = "The port of the Load Balancer listener"
  value       = aws_lb_listener.listener.port
}

output "listener_protocol" {
  description = "The protocol of the Load Balancer listener"
  value       = aws_lb_listener.listener.protocol
}

output "listener_ssl_policy" {
  description = "The SSL policy of the Load Balancer listener"
  value       = aws_lb_listener.listener.ssl_policy
}

output "listener_certificate_arn" {
  description = "The ARN of the certificate associated with the Load Balancer listener"
  value       = aws_lb_listener.listener.certificate_arn
}

output "listener_default_action" {
  description = "The default action of the Load Balancer listener"
  value       = aws_lb_listener.listener.default_action
}

#--------------------------------------------------------------------
# Target Groups Module
#--------------------------------------------------------------------

output "target_group_arn" {
  description = "The ARN of the Target Group"
  value       = var.nlb_listener.target_group != null ? aws_lb_target_group.default[0].arn : null
}

output "target_group_id" {
  description = "The ID of the Target Group"
  value       = var.nlb_listener.target_group != null ? aws_lb_target_group.default[0].id : null
}

output "target_group_port" {
  description = "The port of the Target Group"
  value       = var.nlb_listener.target_group != null ? aws_lb_target_group.default[0].port : null
}

output "target_group_protocol" {
  description = "The protocol of the Target Group"
  value       = var.nlb_listener.target_group != null ? aws_lb_target_group.default[0].protocol : null
}

output "target_group_health_check" {
  description = "The health check configuration of the Target Group"
  value       = var.nlb_listener.target_group != null ? aws_lb_target_group.default[0].health_check : null
}
