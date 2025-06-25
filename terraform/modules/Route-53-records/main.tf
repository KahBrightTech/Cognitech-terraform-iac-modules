#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_region" "current" {}

#--------------------------------------------------------------------
# Cretes the Route 53 records
#--------------------------------------------------------------------
resource "aws_route53_record" "records" {
  zone_id        = var.dns_record.zone_id
  name           = var.dns_record.name
  type           = var.dns_record.type
  ttl            = var.dns_record.ttl
  records        = var.dns_record.records
  set_identifier = var.dns_record.set_identifier != null ? var.dns_record.set_identifier : var.dns_record.weight != null ? "weighted_routing_policy" : null

  dynamic "weighted_routing_policy" {
    for_each = var.dns_record.weight != null ? [1] : []
    content {
      weight = var.dns_record.weight
    }

  }
}

#--------------------------------------------------------------------
# Cretes the Route 53  alias records
#--------------------------------------------------------------------
resource "aws_route53_record" "alias" {
  count   = (var.dns_alias != null) ? var.dns_alias.zone_id != null && var.dns_alias.alias.zone_id != null ? 1 : 0 : 0
  name    = var.dns_alias
  type    = "A"
  zone_id = var.dns_alias.zone_id
  alias {
    name                   = var.dns_alias.alias.name
    zone_id                = var.dns_alias.alias.zone_id
    evaluate_target_health = var.dns_alias.alias.evaluate_target_health
  }
}
