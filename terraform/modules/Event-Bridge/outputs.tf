output "event_bus_arn" {
  description = "The ARN of the EventBridge event bus. If a custom bus is not created, returns the default bus ARN."
  value       = length(aws_cloudwatch_event_bus.this) > 0 ? aws_cloudwatch_event_bus.this[0].arn : format("arn:aws:events:%s:%s:event-bus/default", data.aws_region.current.name, data.aws_caller_identity.current.account_id)
}

output "event_rule_arn" {
  description = "The ARN of the EventBridge rule."
  value       = aws_cloudwatch_event_rule.this.arn
}

output "event_target_arn" {
  description = "The ARN of the EventBridge target."
  value       = aws_cloudwatch_event_target.this.arn
}

