#--------------------------------------------------------------------
# Target Groups Module
#--------------------------------------------------------------------

output "target_group_arn" {
  description = "The ARN of the Target Group"
  value       = aws_lb_target_group.tg.arn
}

output "target_group_id" {
  description = "The ID of the Target Group"
  value       = aws_lb_target_group.tg.id
}

output "target_group_port" {
  description = "The port of the Target Group"
  value       = aws_lb_target_group.tg.port
}

output "target_group_protocol" {
  description = "The protocol of the Target Group"
  value       = aws_lb_target_group.tg.protocol
}

output "target_group_attachments" {
  description = "The attachments of the Target Group"
  value       = var.target_group.attachments != null ? aws_lb_target_group_attachment.attachment : []
}
