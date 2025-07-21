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

  # Dynamic block for fixed-response default action
  dynamic "default_action" {
    for_each = var.listener.fixed_response != null ? [var.listener.fixed_response] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = default_action.value.content_type
        message_body = default_action.value.message_body
        status_code  = default_action.value.status_code
      }
    }
  }

  # Dynamic block for forward default action
  dynamic "default_action" {
    for_each = var.listener.forward != null ? [var.listener.forward] : []
    content {
      type             = "forward"
      target_group_arn = default_action.value.target_group_arn
    }
  }
}



