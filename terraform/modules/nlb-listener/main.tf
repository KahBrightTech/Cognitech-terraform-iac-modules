#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#-------------------------------------------------------------------------------------------------------------------
# Load Balancer Configuration. Creates default listener for the Load Balancer.
#-------------------------------------------------------------------------------------------------------------------
resource "aws_lb_listener" "listener" {
  load_balancer_arn = var.nlb_listener.load_balancer_arn
  port              = var.nlb_listener.port
  protocol          = var.nlb_listener.protocol
  ssl_policy        = var.nlb_listener.ssl_policy
  certificate_arn   = var.nlb_listener.certificate_arn

  # Dynamic block for forward default action using external target group
  dynamic "default_action" {
    for_each = var.nlb_listener.forward != null ? [1] : []
    content {
      type             = "forward"
      target_group_arn = var.nlb_listener.forward.target_group_arn
    }
  }

  # Dynamic block for forward default action using module-created target group
  dynamic "default_action" {
    for_each = var.nlb_listener.forward == null && var.nlb_listener.target_group != null ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.default[0].arn
    }
  }

  depends_on = [aws_lb_target_group.default]
}

#-------------------------------------------------------------------------------------------------------------------
# Create Default target group for the Load Balancer
#-------------------------------------------------------------------------------------------------------------------
resource "aws_lb_target_group" "default" {
  count    = var.nlb_listener.target_group != null ? 1 : 0
  name     = var.nlb_listener.target_group.name
  port     = var.nlb_listener.target_group.port
  protocol = var.nlb_listener.target_group.protocol

  dynamic "stickiness" {
    for_each = var.nlb_listener.target_group.stickiness != null ? [var.nlb_listener.target_group.stickiness] : []
    content {
      enabled         = stickiness.value.enabled
      type            = stickiness.value.type
      cookie_duration = stickiness.value.duration
    }
  }

  vpc_id = var.nlb_listener.target_group.vpc_id

  dynamic "health_check" {
    for_each = var.nlb_listener.target_group.health_check != null ? [var.nlb_listener.target_group.health_check] : []
    content {
      enabled             = health_check.value.enabled
      protocol            = health_check.value.protocol
      port                = health_check.value.port
      path                = health_check.value.path
      interval            = health_check.value.interval
      timeout             = health_check.value.timeout
      healthy_threshold   = health_check.value.healthy_threshold
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }

  tags = merge(var.common.tags, {
    Name = "${var.common.account_name}-${var.common.region_prefix}-tg-${var.nlb_listener.target_group.name}"
  })
}

#-------------------------------------------------------------------------------------------------------------------
# Create Default target group attachment for the Load Balancer
#-------------------------------------------------------------------------------------------------------------------

resource "aws_lb_target_group_attachment" "default" {
  count            = var.nlb_listener.target_group != null && try(var.nlb_listener.target_group.attachment != null, false) ? 1 : 0
  target_group_arn = aws_lb_target_group.default[0].arn
  target_id        = try(var.nlb_listener.target_group.attachment.target_id, null)
  port             = try(var.nlb_listener.target_group.attachment.port, null)
}
