#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#-------------------------------------------------------------------------------------------------------------------
# Load Balancer Configuration. Creates default listener for the Load Balancer.
#-------------------------------------------------------------------------------------------------------------------
resource "aws_lb_listener" "listener" {
  load_balancer_arn = var.listener.load_balancer_arn
  port              = var.listener.port
  protocol          = var.listener.protocol
  ssl_policy        = var.listener.ssl_policy
  certificate_arn   = var.listener.certificate_arn
  # Dynamic block for forward default action
  dynamic "default_action" {
    for_each = var.listener.forward != null ? [var.listener.forward] : []
    content {
      type             = "forward"
      target_group_arn = default_action.value.target_group_arn

      # Dynamic stickiness block (optional)
      dynamic "stickiness" {
        for_each = default_action.value.stickiness != null ? [default_action.value.stickiness] : []
        content {
          enabled         = stickiness.value.enabled
          type            = stickiness.value.type
          cookie_duration = stickiness.value.duration
        }
      }
    }
  }
}

#-------------------------------------------------------------------------------------------------------------------
# Create Default target group for the Load Balancer
#-------------------------------------------------------------------------------------------------------------------
resource "aws_lb_target_group" "default" {
  count    = var.listener.target_group != null ? 1 : 0
  name     = var.listener.name
  port     = var.listener.port
  protocol = var.listener.protocol
  vpc_id   = var.listener.vpc_id

  health_check {
    path                = var.listener.health_check.path
    interval            = var.listener.health_check.interval
    timeout             = var.listener.health_check.timeout
    healthy_threshold   = var.listener.health_check.healthy_threshold
    unhealthy_threshold = var.listener.health_check.unhealthy_threshold
  }

  tags = merge(var.common.tags, {
    Name = "${var.common.account_name}-${var.common.region_prefix}-tg-${var.listener.name}"
  })
}

#-------------------------------------------------------------------------------------------------------------------
# Create Default target group attachment for the Load Balancer
#-------------------------------------------------------------------------------------------------------------------

resource "aws_lb_target_group_attachment" "default" {
  count            = var.listener.target_group && var.listener.target_group.attachment != null ? 1 : 0
  target_group_arn = aws_lb_target_group.default.arn
  target_id        = var.listener.target_group.attachment.target_id
  port             = var.listener.target_group.attachment.port
}
