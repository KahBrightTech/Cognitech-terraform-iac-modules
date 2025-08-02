#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#-------------------------------------------------------------------------------------------------------------------
# Create Default target group for the Load Balancer
#-------------------------------------------------------------------------------------------------------------------
resource "aws_ssm_document" "ssm_doc" {
  name            = "${var.common.account_name_abr}-${var.common.region_prefix}-${var.ssm_document.name}"
  content         = var.ssm_document.content
  document_type   = try(var.ssm_document.document_type, "Command")
  document_format = try(var.ssm_document.document_format, "YAML")

  tags = merge(
    var.common.tags,
    {
      Name = "${var.common.account_name_abr}-${var.common.region_prefix}-${var.ssm_document.name}"
    }
  )
}

#-------------------------------------------------------------------------------------------------------------------
# SSM Association for the SSM Document (Conditional)
#-------------------------------------------------------------------------------------------------------------------
resource "aws_ssm_association" "ssm_association" {
  count = try(var.ssm_document.create_association, false) ? 1 : 0

  name = aws_ssm_document.ssm_doc.name

  dynamic "targets" {
    for_each = var.ssm_document.targets != null ? [1] : []
    content {
      key    = var.ssm_document.targets.key
      values = var.ssm_document.targets.values
    }
  }
  parameters = var.ssm_document.parameters

  schedule_expression = var.ssm_document.schedule_expression
  dynamic "output_location" {
    for_each = var.ssm_document.output_location != null ? [1] : []
    content {
      s3_bucket_name = var.ssm_document.output_location.s3_bucket_name
      s3_key_prefix  = var.ssm_document.output_location.s3_key_prefix
    }
  }
}

