output "arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.private.arn
}

output "id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.private.id
}

output "policy" {
  description = "The policy of the S3 bucket"
  value       = length(aws_s3_bucket_policy.default) > 0 ? aws_s3_bucket_policy.default[0].policy : null
}

output "name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.private.bucket
}

output "bucket_name" {
  description = "The name of the S3 bucket"
  value       = local.bucket_name
}

output "versioning" {
  description = "The versioning state of the S3 bucket"
  value       = aws_s3_bucket.private.versioning[0].enabled
}

output "replication_configuration" {
  description = "The replication configuration of the S3 bucket"
  value       = length(aws_s3_bucket_replication_configuration.replication) > 0 ? aws_s3_bucket_replication_configuration.replication[0].rules : null
}

output "server_side_encryption" {
  description = "The server-side encryption configuration of the S3 bucket"
  value       = aws_s3_bucket_server_side_encryption_configuration.bucket.rule[0].apply_server_side_encryption_by_default.sse_algorithm
}

output "lifecycle_rules" {
  description = "The lifecycle rules of the S3 bucket"
  value       = aws_s3_bucket.private.lifecycle_rule
}
