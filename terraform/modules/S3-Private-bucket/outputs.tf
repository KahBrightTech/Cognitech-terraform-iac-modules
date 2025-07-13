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

output "encryption" {
  description = "The encryption configuration of the S3 bucket"
  value = length(aws_s3_bucket_server_side_encryption_configuration.bucket) > 0 ? {
    enabled            = true
    sse_algorithm      = [for rule in aws_s3_bucket_server_side_encryption_configuration.bucket[0].rule : rule.apply_server_side_encryption_by_default[0].sse_algorithm][0]
    kms_master_key_id  = [for rule in aws_s3_bucket_server_side_encryption_configuration.bucket[0].rule : rule.apply_server_side_encryption_by_default[0].kms_master_key_id][0]
    bucket_key_enabled = [for rule in aws_s3_bucket_server_side_encryption_configuration.bucket[0].rule : rule.bucket_key_enabled][0]
    } : {
    enabled            = false
    sse_algorithm      = null
    kms_master_key_id  = null
    bucket_key_enabled = false
  }
}
