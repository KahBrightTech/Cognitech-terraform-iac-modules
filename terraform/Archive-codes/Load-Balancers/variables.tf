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
#       port     = optional(string)
#       protocol = optional(string)
#       fixed_response = optional(object({
#         content_type = optional(string, "text/plain")
#         message_body = optional(string, "Oops! The page you are looking for does not exist.")
#         status_code  = optional(string, "200")
#       }))
#     }))
#   })
#   default = null
# }

variable "load_balancer" {
  description = "Load Balancer configuration"
  type = object({
    name            = string
    internal        = optional(bool, false)
    type            = string # "application" or "network"
    security_groups = optional(list(string))
    vpc_name        = string
    subnets         = optional(list(string))
    subnet_mappings = optional(list(object({
      subnet_id            = string
      private_ipv4_address = optional(string)
    })))
    enable_deletion_protection = optional(bool, false)
    enable_access_logs         = optional(bool, false)
    access_logs_bucket         = optional(string)
    access_logs_prefix         = optional(string)
    create_default_listener    = optional(bool, false)
    default_listener = optional(object({
      port            = optional(number, "443")
      protocol        = optional(string, "TLS")
      action_type     = optional(string, "fixed-response")
      certificate_arn = optional(string)
      fixed_response = object({
        content_type = optional(string, "text/plain")
        message_body = optional(string, "Oops! The page you are looking for does not exist.")
        status_code  = optional(string, "200")
      })
    }))
  })
  default = null
  # validation {
  #   condition = (
  #     var.load_balancer == null ||
  #     (
  #       try(var.load_balancer.create_default_listener, false) == false ||
  #       var.load_balancer.default_listener != null
  #     )
  #   )
  #   error_message = "If 'create_default_listener' is true, 'default_listener' must not be null."
  # }
}

