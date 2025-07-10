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
