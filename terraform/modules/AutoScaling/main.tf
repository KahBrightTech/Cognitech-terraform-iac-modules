#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
# Get stable role ARNs using sort() to ensure consistent ordering
#--------------------------------------------------------------------
# Creates Load Balancers
#--------------------------------------------------------------------
# module "alb" {
#   source        = "../Load-Balancers"
#   common        = var.common
#   load_balancer = var.load_balancer
# }

# #--------------------------------------------------------------------
# # Creates Target Groups
# #--------------------------------------------------------------------
# module "target_group" {
#   source       = "../Target-Groups"
#   common       = var.common
#   target_group = var.target_group
# }

# #--------------------------------------------------------------------
# # Creates Launch Templates
# #--------------------------------------------------------------------
# module "launch_template" {
#   source          = "../Launch-Template"
#   common          = var.common
#   launch_template = var.launch_template
# }

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
  launch_configuration      = module.launch_template.name
  vpc_zone_identifier       = [aws_subnet.example1.id, aws_subnet.example2.id]
  target_group_arns         = var.Autoscaling_group.attach_target_groups
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
