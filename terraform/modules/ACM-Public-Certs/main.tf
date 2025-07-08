#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#--------------------------------------------------------------------
# Locals
#--------------------------------------------------------------------
resource "aws_acm_certificate" "main" {
  domain_name       = var.certificate.domain_name
  validation_method = var.certificate.validation_method

  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.certificate.name}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
