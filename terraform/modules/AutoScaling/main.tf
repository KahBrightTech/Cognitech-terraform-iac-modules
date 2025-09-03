#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
# Get stable role ARNs using sort() to ensure consistent ordering
#--------------------------------------------------------------------
# Creates Auto Scaling Groups
#--------------------------------------------------------------------

resource "aws_autoscaling_group" "main" {
  name                      = "${var.common.account_name}-${var.common.region_prefix}-${var.Autoscaling_group.name}-asg"
  max_size                  = var.Autoscaling_group.max_size
  min_size                  = var.Autoscaling_group.min_size
  health_check_grace_period = var.Autoscaling_group.health_check_grace_period
  health_check_type         = var.Autoscaling_group.health_check_type
  desired_capacity          = var.Autoscaling_group.desired_capacity
  force_delete              = var.Autoscaling_group.force_delete
  launch_template {
    id      = var.Autoscaling_group.launch_template.id
    version = var.Autoscaling_group.launch_template.version
  }
  vpc_zone_identifier = var.Autoscaling_group.subnet_ids
  target_group_arns   = var.Autoscaling_group.attach_target_groups
  dynamic "timeouts" {
    for_each = var.Autoscaling_group.timeouts != null ? [var.Autoscaling_group.timeouts] : []
    content {
      delete = lookup(timeouts.value, "delete", null)
    }
  }

  dynamic "tag" {
    for_each = var.Autoscaling_group.tags != null ? var.Autoscaling_group.tags : {}
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  dynamic "tag" {
    for_each = var.Autoscaling_group.additional_tags != null ? var.Autoscaling_group.additional_tags : []
    content {
      key                 = tag.value.key
      value               = tag.value.value
      propagate_at_launch = lookup(tag.value, "propagate_at_launch", true)
    }
  }

}
