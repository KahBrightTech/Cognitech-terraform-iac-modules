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
