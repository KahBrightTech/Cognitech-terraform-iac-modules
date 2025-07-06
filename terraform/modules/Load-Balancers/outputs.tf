#--------------------------------------------------------------------
# Load Balancer Configuration
#--------------------------------------------------------------------

output "name" {
  description = "value of the Load Balancer name"
  value       = aws_lb.main.name
}
output "arn" {
  description = "value of the Load Balancer ARN"
  value       = aws_lb.main.arn
}
output "dns_name" {
  description = "value of the Load Balancer DNS name"
  value       = aws_lb.main.dns_name
}
output "zone_id" {
  description = "value of the Load Balancer zone ID"
  value       = aws_lb.main.zone_id
}
output "load_balancer_type" {
  description = "value of the Load Balancer type (application or network)"
  value       = aws_lb.main.load_balancer_type
}
output "internal" {
  description = "value of the Load Balancer internal flag"
  value       = aws_lb.main.internal
}
output "security_groups" {
  description = "value of the Load Balancer security groups"
  value       = aws_lb.main.security_groups
}
output "subnets" {
  description = "value of the Load Balancer subnets"
  value       = aws_lb.main.subnets
}
output "subnet_mappings" {
  description = "value of the Load Balancer subnet mappings"
  value       = aws_lb.main.subnet_mapping
}
output "enable_deletion_protection" {
  description = "value of the Load Balancer deletion protection flag"
  value       = aws_lb.main.enable_deletion_protection
}
output "access_logs" {
  description = "value of the Load Balancer access logs configuration"
  value       = aws_lb.main.access_logs
}
output "access_logs_bucket" {
  description = "value of the Load Balancer access logs bucket"
  value       = aws_lb.main.access_logs[0].bucket
}
output "access_logs_prefix" {
  description = "value of the Load Balancer access logs prefix"
  value       = aws_lb.main.access_logs[0].prefix
}

output "default_listener" {
  description = "value of the Load Balancer default listener configuration"
  value       = aws_lb_listener.default
}

output "default_listener_arn" {
  description = "ARN of the default listener for the Load Balancer"
  value       = aws_lb_listener.default.arn
}

output "default_listener_port" {
  description = "Port of the default listener for the Load Balancer"
  value       = aws_lb_listener.default.port
}

output "default_listener_protocol" {
  description = "Protocol of the default listener for the Load Balancer"
  value       = aws_lb_listener.default.protocol
}

output "default_listener_fixed_response" {
  description = "Fixed response configuration of the default listener for the Load Balancer"
  value       = aws_lb_listener.default.default_action[0].fixed_response
}

output "default_listener_fixed_response_content_type" {
  description = "Content type of the fixed response for the default listener"
  value       = aws_lb_listener.default.default_action[0].fixed_response[0].content_type
}

output "default_listener_fixed_response_message_body" {
  description = "Message body of the fixed response for the default listener"
  value       = aws_lb_listener.default.default_action[0].fixed_response[0].message_body
}

output "default_listener_fixed_response_status_code" {
  description = "Status code of the fixed response for the default listener"
  value       = aws_lb_listener.default.default_action[0].fixed_response[0].status_code
}
