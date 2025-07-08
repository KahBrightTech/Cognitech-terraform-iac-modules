#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#--------------------------------------------------------------------
# Locals
#--------------------------------------------------------------------
locals {
  lb_type_suffix = var.load_balancer.type == "application" ? "alb" : "nlb"
  lb_name        = "${var.common.account_name_abr}-${var.common.region_prefix}-${var.load_balancer.name}-${local.lb_type_suffix}"
}

#-------------------------------------------------------------------------------------------------------------------
# Load Balancer Configuration. Allows creation of Application Load Balancers (ALB) and Network Load Balancers (NLB).
#-------------------------------------------------------------------------------------------------------------------
resource "aws_lb" "main" {
  name                       = local.lb_name
  internal                   = var.load_balancer.internal
  load_balancer_type         = var.load_balancer.type
  security_groups            = var.load_balancer.security_groups
  subnets                    = var.load_balancer.type == "network" && var.load_balancer.subnet_mappings != null ? null : var.load_balancer.subnets
  enable_deletion_protection = var.load_balancer.enable_deletion_protection
  # If private IPs specified (only for NLB)
  dynamic "subnet_mapping" {
    for_each = var.load_balancer.type == "network" && var.load_balancer.subnet_mappings != null ? var.load_balancer.subnet_mappings : []
    content {
      subnet_id            = subnet_mapping.value.subnet_id
      private_ipv4_address = subnet_mapping.value.private_ipv4_address
    }
  }
  # Optional access logs for ALB
  dynamic "access_logs" {
    for_each = var.load_balancer.type == "application" && var.load_balancer.enable_access_logs ? [1] : []
    content {
      bucket  = var.load_balancer.access_logs_bucket
      prefix  = "${data.aws_caller_identity.current.account_id}/elb-logs/${var.load_balancer.vpc_name}"
      enabled = true
    }
  }
  tags = merge(var.common.tags, {
    Name = local.lb_name
  })
}

#-------------------------------------------------------------------------------------------------------------------
# Load Balancer Configuration. Creates default listener for the Load Balancer.
#-------------------------------------------------------------------------------------------------------------------
resource "aws_lb_listener" "default" {
  count             = var.load_balancer.create_default_listener && var.load_balancer.default_listener != null ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = var.load_balancer.default_listener.port
  protocol          = var.load_balancer.default_listener.protocol
  ssl_policy        = var.load_balancer.default_listener.protocol == "HTTPS" || var.load_balancer.default_listener.protocol == "TLS" ? var.load_balancer.default_listener.ssl_policy : null
  certificate_arn   = var.load_balancer.default_listener.protocol == "HTTPS" || var.load_balancer.default_listener.protocol == "TLS" ? var.load_balancer.default_listener.certificate_arn : null

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = var.load_balancer.default_listener.fixed_response.content_type
      message_body = var.load_balancer.default_listener.fixed_response.message_body
      status_code  = var.load_balancer.default_listener.fixed_response.status_code
    }
  }
}



