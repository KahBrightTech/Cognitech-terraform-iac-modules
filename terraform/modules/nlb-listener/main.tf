#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#-------------------------------------------------------------------------------------------------------------------
# Create Default target group for the Load Balancer
#-------------------------------------------------------------------------------------------------------------------
module "nlb_target_group" {
  count  = var.nlb_listener.action == "forward" && var.nlb_listener.target_group != null ? 1 : 0
  source = "../Target-groups"

  common = var.common
  target_group = merge(
    var.nlb_listener.target_group,
    {
      vpc_id = var.nlb_listener.vpc_id
    }
  )
}

#-------------------------------------------------------------------------------------------------------------------
# Load Balancer Configuration. Creates default listener for the Load Balancer.
#-------------------------------------------------------------------------------------------------------------------
resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = var.nlb_listener.nlb_arn
  port              = var.nlb_listener.port
  protocol          = var.nlb_listener.protocol
  ssl_policy        = var.nlb_listener.protocol == "TLS" ? var.nlb_listener.ssl_policy : null
  certificate_arn   = var.nlb_listener.protocol == "TLS" ? var.nlb_listener.certificate_arn : null
  default_action {
    type             = var.nlb_listener.action
    target_group_arn = module.nlb_target_group[0].target_group_arn
  }
  tags = merge(
    var.common.tags,
    {
      Name = "${var.common.account_name_abr}-${var.common.region_prefix}-${var.nlb_listener.port}"
    }
  )
}



#-------------------------------------------------------------------------------------------------------------------
# SNI Certificates for NLB
#-------------------------------------------------------------------------------------------------------------------

resource "aws_lb_listener_certificate" "sni_certificates" {
  for_each        = var.nlb_listener.protocol == "HTTPS" && var.nlb_listener.sni_certificates != null ? { for cert in var.nlb_listener.sni_certificates : cert.domain_name => cert } : {}
  certificate_arn = each.value.certificate_arn
  listener_arn    = aws_lb_listener.nlb_listener.arn
}
