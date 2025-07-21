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
  # Dynamic block for forward default action
  dynamic "default_action" {
    for_each = var.nlb_listener.forward != null ? [var.nlb_listener.forward] : []
    content {
      type             = "forward"
      target_group_arn = default_action.value.target_group_arn
    }
  }
}

#-------------------------------------------------------------------------------------------------------------------
# Create Default target group for the Load Balancer
#-------------------------------------------------------------------------------------------------------------------
resource "aws_lb_target_group" "default" {
  count    = var.nlb_listener.target_group != null ? 1 : 0
  name     = var.nlb_listener.target_group.name
  port     = var.nlb_listener.target_group.port
  protocol = var.nlb_listener.target_group.protocol
  stickiness {
    enabled         = var.nlb_listener.target_group.stickiness.enabled
    type            = var.nlb_listener.target_group.stickiness.type
    cookie_duration = var.nlb_listener.target_group.stickiness.duration
  }
  vpc_id = var.nlb_listener.target_group.vpc_id

  health_check {
    enabled             = var.nlb_listener.target_group.health_check.enabled
    protocol            = var.nlb_listener.target_group.health_check.protocol
    port                = var.nlb_listener.target_group.health_check.port
    path                = var.nlb_listener.target_group.health_check.path
    interval            = var.nlb_listener.target_group.health_check.interval
    timeout             = var.nlb_listener.target_group.health_check.timeout
    healthy_threshold   = var.nlb_listener.target_group.health_check.healthy_threshold
    unhealthy_threshold = var.nlb_listener.target_group.health_check.unhealthy_threshold
  }

  tags = merge(var.common.tags, {
    Name = "${var.common.account_name}-${var.common.region_prefix}-tg-${var.nlb_listener.target_group.name}"
  })
}

#-------------------------------------------------------------------------------------------------------------------
# Create Default target group attachment for the Load Balancer
#-------------------------------------------------------------------------------------------------------------------

resource "aws_lb_target_group_attachment" "default" {
  count            = var.nlb_listener.target_group != null && var.nlb_listener.target_group.attachment != null ? 1 : 0
  target_group_arn = aws_lb_target_group.default[0].arn
  target_id        = var.nlb_listener.target_group.attachment.target_id
  port             = var.nlb_listener.target_group.attachment.port
}
