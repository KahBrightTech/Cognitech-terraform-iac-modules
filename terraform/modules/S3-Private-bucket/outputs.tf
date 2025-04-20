output "arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.private.arn
}

output "id" {
  description = "The ID of the S3 bucket"
  value       = aws_s3_bucket.private.id
}
