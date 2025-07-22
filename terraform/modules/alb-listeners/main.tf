#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#-------------------------------------------------------------------------------------------------------------------
# Create Default target group for the Load Balancer
#-------------------------------------------------------------------------------------------------------------------
module "alb_target_group" {
  count  = var.alb_listener.action == "forward" && var.alb_listener.target_group != null ? 1 : 0
  source = "../Target-groups"

  common = var.common
  target_group = merge(
    var.alb_listener.target_group,
    {
      vpc_id = var.alb_listener.vpc_id
    }
  )
}

#-------------------------------------------------------------------------------------------------------------------
# Load Balancer Configuration. Creates default listener for the Load Balancer.
#-------------------------------------------------------------------------------------------------------------------
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = var.alb_listener.alb_arn
  port              = var.alb_listener.port
  protocol          = var.alb_listener.protocol
  ssl_policy        = var.alb_listener.ssl_policy
  certificate_arn   = var.alb_listener.certificate_arn

  default_action {
    type             = var.alb_listener.action
    target_group_arn = var.alb_listener.action == "forward" && var.alb_listener.target_group != null && length(module.alb_target_group) > 0 ? module.alb_target_group[0].target_group_arn : null

    # Dynamic block for fixed-response default action
    dynamic "fixed_response" {
      for_each = var.alb_listener.action == "fixed-response" ? [var.alb_listener.fixed_response] : []
      content {
        content_type = fixed_response.value.content_type
        message_body = fixed_response.value.message_body
        status_code  = fixed_response.value.status_code
      }
    }
  }
  tags = merge(
    var.common.tags,
    {
      Name = "${var.common.account_name_abr}-${var.common.region_prefix}-${var.alb_listener.port}"
    }
  )
}


#-------------------------------------------------------------------------------------------------------------------
# SNI Certificates for ALB
#-------------------------------------------------------------------------------------------------------------------

resource "aws_lb_listener_certificate" "sni_certificates" {
  for_each        = var.alb_listener.protocol == "HTTPS" && var.alb_listener.sni_certificates != null ? { for cert in var.alb_listener.sni_certificates : cert.domain_name => cert } : {}
  certificate_arn = each.value.certificate_arn
  listener_arn    = aws_lb_listener.alb_listener.arn
}
