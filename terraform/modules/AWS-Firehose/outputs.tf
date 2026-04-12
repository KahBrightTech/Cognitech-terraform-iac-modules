output "firehose_delivery_stream_arn" {
  description = "ARN of the Kinesis Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.main.arn
}

output "firehose_delivery_stream_name" {
  description = "Name of the Kinesis Firehose delivery stream"
  value       = aws_kinesis_firehose_delivery_stream.main.name
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for Firehose"
  value       = var.firehose.enable_cloudwatch_logging ? aws_cloudwatch_log_group.firehose[0].name : null
}

