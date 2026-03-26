output "event_bus_arn" {
  description = "The ARN of the EventBridge event bus."
  value       = aws_cloudwatch_event_bus.this.arn
}

output "event_rule_arn" {
  description = "The ARN of the EventBridge rule."
  value       = aws_cloudwatch_event_rule.this.arn
}

output "event_target_arn" {
  description = "The ARN of the EventBridge target."
  value       = aws_cloudwatch_event_target.this.arn
}

