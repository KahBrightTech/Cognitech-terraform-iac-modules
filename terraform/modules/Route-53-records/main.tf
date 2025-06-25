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
