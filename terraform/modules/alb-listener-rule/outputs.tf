#--------------------------------------------------------------------
# ALB Listener Rule Configuration
#--------------------------------------------------------------------

output "alb_listener_rules" {
  description = "ALB Listener Rules"
  value = {
    for key, item in aws_lb_listener_rule.rule :
    key => {
      action     = item.action
      conditions = item.condition
      arn        = item.arn
      id         = item.id
      priority   = item.priority
    }
  }

}
