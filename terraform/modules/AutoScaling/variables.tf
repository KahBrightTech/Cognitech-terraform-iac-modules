variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global           = bool
    tags             = map(string)
    account_name     = string
    region_prefix    = string
    account_name_abr = optional(string)
  })
}
# variable "load_balancer" {
#   description = "Load Balancer configuration"
#   type = object({
#     name            = string
#     internal        = optional(bool, false)
#     type            = string # "application" or "network"
#     security_groups = optional(list(string))
#     vpc_name        = string
#     vpc_name_abr    = optional(string)
#     subnets         = optional(list(string))
#     subnet_mappings = optional(list(object({
#       subnet_id            = string
#       private_ipv4_address = optional(string)
#     })))
#     enable_deletion_protection = optional(bool, false)
#     enable_access_logs         = optional(bool, false)
#     access_logs_bucket         = optional(string)
#     access_logs_prefix         = optional(string)
#     create_default_listener    = optional(bool, false)
#     default_listener = optional(object({
#       port            = optional(number, 443)
#       protocol        = optional(string, "HTTPS")
#       action_type     = optional(string, "fixed-response")
#       ssl_policy      = optional(string, "ELBSecurityPolicy-2016-08")
#       certificate_arn = optional(string)
#       fixed_response = object({
#         content_type = optional(string, "text/plain")
#         message_body = optional(string, "Oops! The page you are looking for does not exist.")
#         status_code  = optional(string, "200")
#       })
#     }))
#   })
#   default = null
# }

# variable "target_group" {
#   description = "Target Group configuration"
#   type = object({
#     name               = optional(string)
#     port               = optional(number)
#     protocol           = optional(string)
#     preserve_client_ip = optional(bool)
#     target_type        = optional(string)
#     tags               = optional(map(string))
#     vpc_id             = string
#     vpc_name_abr       = optional(string)
#     attachments = optional(list(object({
#       target_id = optional(string)
#       port      = optional(number)
#     })))
#     stickiness = optional(object({
#       enabled         = optional(bool)
#       type            = optional(string)
#       cookie_duration = optional(number)
#       cookie_name     = optional(string)
#     }))
#     health_check = optional(object({
#       protocol = optional(string)
#       port     = optional(number)
#       path     = optional(string)
#       matcher  = optional(string)
#     }))
#   })
#   default = null
# }

variable "Autoscaling_group" {
  description = "Auto Scaling configuration"
  type = object({
    name                      = optional(string)
    min_size                  = optional(number)
    max_size                  = optional(number)
    health_check_type         = optional(string)
    health_check_grace_period = optional(number)
    force_delete              = optional(bool)
    desired_capacity          = optional(number)
    subnet_ids                = optional(list(string))
    attach_target_groups      = optional(list(string))
    launch_configuration      = optional(string)
    timeouts = optional(object({
      delete = optional(string)
    }))
    tags = optional(map(string))
    additional_tags = optional(list(object({
      key                 = string
      value               = string
      propagate_at_launch = optional(bool, true)
    })))
  })
  default = null
}
