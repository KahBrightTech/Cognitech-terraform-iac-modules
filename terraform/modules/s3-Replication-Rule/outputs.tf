#--------------------------------------------------------------------
# Outputs for S3 Replication Rule Module
#--------------------------------------------------------------------
output "s3_replication_rule" {
  description = "S3 Replication Rule configuration"
  value       = var.s3_replication_rule
}
output "source_bucket" {
  description = "Source S3 bucket for replication"
  value       = aws_s3_bucket.source.id
}
output "destination_bucket" {
  description = "Destination S3 bucket for replication"
  value       = aws_s3_bucket.destination.id
}
output "replication_role_arn" {
  description = "ARN of the IAM role used for S3 replication"
  value       = aws_iam_role.replication.arn
}
output "replication_configuration" {
  description = "S3 replication configuration"
  value       = aws_s3_bucket_replication_configuration.replication
}
output "source_bucket_versioning" {
  description = "Versioning configuration of the source S3 bucket"
  value       = aws_s3_bucket_versioning.source.versioning_configuration
}

