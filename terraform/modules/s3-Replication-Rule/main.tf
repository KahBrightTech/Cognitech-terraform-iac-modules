#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#--------------------------------------------------------------------
# Creates Destination S3 Buckets for Replication
#--------------------------------------------------------------------
resource "aws_s3_bucket" "destination" {
  bucket = var.s3_replication_rule.destination.bucket_name
}

resource "aws_s3_bucket_versioning" "destination" {
  bucket = aws_s3_bucket.destination.id
  versioning_configuration {
    status = "Enabled"
  }
}

#--------------------------------------------------------------------
# Creates Source S3 Buckets for Replication
#--------------------------------------------------------------------
resource "aws_s3_bucket" "source" {
  bucket = var.s3_replication_rule.source.bucket_name
}

resource "aws_s3_bucket_acl" "source_bucket_acl" {
  bucket = aws_s3_bucket.source.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}

#--------------------------------------------------------------------
# Creates S3 Replication Rule
#--------------------------------------------------------------------
resource "aws_s3_bucket_replication_configuration" "replication" {
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.source]

  role   = var.s3_replication_rule.role_arn
  bucket = aws_s3_bucket.source.id

  rule {
    id     = var.s3_replication_rule.rule_name != null ? var.s3_replication_rule.rule_name : "default-replication-rule"
    status = "Enabled"
    destination {
      bucket        = aws_s3_bucket.destination.arn
      storage_class = var.s3_replication_rule.destination.storage_class
    }
  }
}



