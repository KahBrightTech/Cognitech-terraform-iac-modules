#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_region" "current" {}

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
