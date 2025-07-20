#--------------------------------------------------------------------
# Target Groups Module
#--------------------------------------------------------------------

output "target_group_arn" {
  description = "The ARN of the Target Group"
  value       = aws_lb_target_group.target_group.arn
}

output "target_group_id" {
  description = "The ID of the Target Group"
  value       = aws_lb_target_group.target_group.id
}

output "target_group_port" {
  description = "The port of the Target Group"
  value       = aws_lb_target_group.target_group.port
}

output "target_group_protocol" {
  description = "The protocol of the Target Group"
  value       = aws_lb_target_group.target_group.protocol
}

output "target_group_health_check" {
  description = "The health check configuration of the Target Group"
  value       = aws_lb_target_group.target_group.health_check
}
