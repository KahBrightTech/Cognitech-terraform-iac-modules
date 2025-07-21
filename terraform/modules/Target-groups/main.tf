#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#-------------------------------------------------------------------------------------------------------------------
# Target Group Configuration. Creates default listener for the Load Balancer.
#-------------------------------------------------------------------------------------------------------------------

resource "aws_lb_target_group" "target_group" {
  name     = var.target_group.name
  port     = var.target_group.port
  protocol = var.target_group.protocol
  stickiness {
    enabled         = var.target_group.stickiness.enabled
    type            = var.target_group.stickiness.type
    cookie_duration = var.target_group.stickiness.duration
  }
  vpc_id = var.target_group.vpc_id

  health_check {
    enabled             = var.target_group.health_check.enabled
    protocol            = var.target_group.health_check.protocol
    port                = var.target_group.health_check.port
    path                = var.target_group.health_check.path
    interval            = var.target_group.health_check.interval
    timeout             = var.target_group.health_check.timeout
    healthy_threshold   = var.target_group.health_check.healthy_threshold
    unhealthy_threshold = var.target_group.health_check.unhealthy_threshold
  }

  tags = merge(var.common.tags, {
    Name = "${var.common.account_name}-${var.common.region_prefix}-tg-${var.target_group.name}"
  })

}

#-------------------------------------------------------------------------------------------------------------------
# Create target group attachment for the Load Balancer
#-------------------------------------------------------------------------------------------------------------------

resource "aws_lb_target_group_attachment" "attachment" {
  count            = var.target_group.attachment != null ? 1 : 0
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = var.target_group.attachment.target_id
  port             = var.target_group.attachment.port
}

