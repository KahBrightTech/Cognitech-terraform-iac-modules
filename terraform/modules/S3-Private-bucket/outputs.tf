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
