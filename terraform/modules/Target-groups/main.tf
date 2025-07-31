#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#-------------------------------------------------------------------------------------------------------------------
# Target Group Configuration. Creates default listener for the Load Balancer.
#-------------------------------------------------------------------------------------------------------------------

resource "aws_lb_target_group" "tg" {
  name               = "${var.common.account_name_abr}-${var.common.region_prefix}-tg-${var.target_group.name}"
  port               = var.target_group.port
  protocol           = var.target_group.protocol
  vpc_id             = var.target_group.vpc_id
  preserve_client_ip = try(var.target_group.preserve_client_ip, null)
  target_type        = var.target_group.target_type

  dynamic "stickiness" {
    for_each = var.target_group.stickiness != null ? [1] : []
    content {
      enabled         = try(var.target_group.stickiness.enabled, null)
      type            = try(var.target_group.stickiness.type, null)
      cookie_duration = try(var.target_group.stickiness.cookie_duration, null)
      cookie_name     = try(var.target_group.stickiness.cookie_name, null)
    }
  }
  dynamic "health_check" {
    for_each = var.target_group.health_check != null ? [1] : []
    content {
      protocol            = var.target_group.health_check.protocol
      port                = var.target_group.health_check.port != var.target_group.port ? var.target_group.health_check.port : null
      path                = var.target_group.health_check.path
      matcher             = var.target_group.health_check.matcher
      interval            = 30
      timeout             = 10
      healthy_threshold   = 3
      unhealthy_threshold = 3
    }
  }

  tags = merge(var.common.tags, {
    Name = "${var.common.account_name}-${var.common.region_prefix}-tg-${var.target_group.name}"
  })

}

#-------------------------------------------------------------------------------------------------------------------
# Create target group attachment for the Load Balancer
#-------------------------------------------------------------------------------------------------------------------

resource "aws_lb_target_group_attachment" "attachment" {
  count            = var.target_group.attachments != null ? length(var.target_group.attachments) : 0
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = var.target_group.attachments[count.index].target_id
  port             = var.target_group.attachments[count.index].port
}

