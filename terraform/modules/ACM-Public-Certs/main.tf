#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_route53_zone" "zone" {
  name         = var.certificate.zone_name
  private_zone = false
}

#--------------------------------------------------------------------
# Locals
#--------------------------------------------------------------------
locals {
  secrets_manager_cfg = try(var.certificate.secrets_manager, var.secrets_manager, {})
  create_cert_secret  = try(local.secrets_manager_cfg.enabled, false)
  cert_secret_name = coalesce(
    try(local.secrets_manager_cfg.name, null),
    format("%s/%s/%s/acm-cert", var.common.account_name, var.common.region_prefix, var.certificate.name)
  )
}

resource "aws_acm_certificate" "main" {
  domain_name               = var.certificate.domain_name
  validation_method         = var.certificate.validation_method
  subject_alternative_names = var.certificate.subject_alternative_names

  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.certificate.name}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "record" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}

resource "aws_acm_certificate_validation" "validation" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.record : record.fqdn]
}

resource "aws_secretsmanager_secret" "acm_certificate" {
  count = local.create_cert_secret ? 1 : 0

  name                    = local.cert_secret_name
  description             = local.secrets_manager_cfg.description
  kms_key_id              = try(local.secrets_manager_cfg.kms_key_id, null)
  recovery_window_in_days = local.secrets_manager_cfg.recovery_window_in_days

  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.certificate.name}-acm-metadata"
    }
  )
}

resource "aws_secretsmanager_secret_version" "acm_certificate" {
  count     = local.create_cert_secret ? 1 : 0
  secret_id = aws_secretsmanager_secret.acm_certificate[0].id
  secret_string = jsonencode({
    certificate_arn         = aws_acm_certificate.main.arn
    certificate_domain_name = aws_acm_certificate.main.domain_name
    certificate_status      = aws_acm_certificate.main.status
    validation_record_fqdns = [for record in aws_route53_record.record : record.fqdn]
    private_key_managed_by  = "AWS ACM"
    private_key_exportable  = false
    note                    = "ACM-issued public certificate private keys are not exportable."
  })

  depends_on = [aws_acm_certificate_validation.validation]
}
