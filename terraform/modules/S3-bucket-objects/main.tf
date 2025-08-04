#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#--------------------------------------------------------------------
# S3 bucket objects
#--------------------------------------------------------------------

resource "aws_s3_object" "objects" {
  for_each = {
    for obj in var.s3_bucket.objects : obj.key => obj
  }
  bucket = var.s3_bucket.bucket_id
  key    = each.value.key
  source = each.value.source
  etag   = each.value.etag
  tags   = each.value.tags
}
