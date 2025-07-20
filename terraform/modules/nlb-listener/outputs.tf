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
  value       = aws_lb_target_group.default.arn
}

output "target_group_id" {
  description = "The ID of the Target Group"
  value       = aws_lb_target_group.default.id
}

output "target_group_port" {
  description = "The port of the Target Group"
  value       = aws_lb_target_group.default.port
}

output "target_group_protocol" {
  description = "The protocol of the Target Group"
  value       = aws_lb_target_group.default.protocol
}

output "target_group_health_check" {
  description = "The health check configuration of the Target Group"
  value       = aws_lb_target_group.default.health_check
}
