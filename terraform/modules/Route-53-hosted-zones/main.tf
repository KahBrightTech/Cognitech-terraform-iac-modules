#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_region" "current" {}

#--------------------------------------------------------------------
# Cretes the Route 53 hosted zones
#--------------------------------------------------------------------
resource "aws_route53_zone" "zones" {
  name = var.route53_zones.name
  vpc {
    vpc_id = var.route53_zones.vpc.id
  }
  comment = var.route53_zones.comment
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.route53_zones.name}-zone"
    }
  )
}
