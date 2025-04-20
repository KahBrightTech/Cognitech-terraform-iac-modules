#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_iam_policy_document" "default" {
  statement {
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_86a86e78734d7c0e",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_EffulgenceTechDataAccess_5be58d87cf2da8e9",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_ReadOnlyAccess_9a4a560bae2c526d"
      ]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:PutObjectAcl",
      "s3:GetObjectAcl",
      "s3:PutObjectVersionAcl",
      "s3:GetObjectVersionAcl",
      "s3:PutObjectVersionTagging",
      "s3:GetObjectVersionTagging",
    ]

    resources = [
      aws_s3_bucket.example.arn,
      "${aws_s3_bucket.example.arn}/*",
    ]
  }
}

locals {
  bucket_name = var.s3.name_override != null ? var.s3.name_override : "${var.common.account_name}-${var.common.region_prefix}-${var.s3.name}"
}

#--------------------------------------------------------------------
# S3 Bucket - Creates a private S3 bucket
#--------------------------------------------------------------------
resource "aws_s3_bucket" "private" {
  bucket = local.bucket_name
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.s3.name}-private"
    }
  )
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = local.bucket_name

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = local.bucket_name

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = local.bucket_name

  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "default" {
  bucket = local.bucket_name
  policy = data.aws_iam_policy_document.default.json
}

resource "aws_s3_bucket_versioning" "bucket" {
  bucket = local.bucket_name

  versioning_configuration {
    status = var.s3.enable_versioning == true ? "Enabled" : "Disabled"
  }

}

