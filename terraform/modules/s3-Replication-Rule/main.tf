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
  provider = aws.central

  bucket = aws_s3_bucket.source.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "source" {
  provider = aws.central

  bucket = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.central
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.source]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.source.id

  rule {
    id = "examplerule"

    filter {
      prefix = "example"
    }

    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.destination.arn
      storage_class = "STANDARD"
    }
  }
}



