
#--------------------------------------------------------------------
# Data Sources
#--------------------------------------------------------------------
data "aws_region" "current" {}

#--------------------------------------------------------------------
# IP Set
#--------------------------------------------------------------------
resource "aws_wafv2_ip_set" "this" {
  name               = "${var.common.account_name_abr}-${var.common.region_prefix}-${var.ip_set.name}-ipset"
  description        = var.ip_set.description != null ? var.ip_set.description : "IP Set for WAF - ${var.ip_set.name}"
  scope              = var.ip_set.scope
  ip_address_version = var.ip_set.ip_address_version
  addresses          = var.ip_set.addresses

  tags = merge(
    var.common.tags,
    {
      Name = "${var.common.account_name_abr}-${var.common.region_prefix}-${var.ip_set.name}-ipset"
    }
  )
}

