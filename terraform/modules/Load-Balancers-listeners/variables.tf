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
variable "listener" {
  description = "Load Balancer listener configuration"
  type = object({
    load_balancer_arn = string
    port              = number
    protocol          = string
    ssl_policy        = optional(string)
    certificate_arn   = optional(string)

    # Default action configuration - either fixed_response OR forward, not both
    fixed_response = optional(object({
      content_type = optional(string, "text/plain")
      message_body = optional(string, "Oops! The page you are looking for does not exist.")
      status_code  = optional(string, "200")
    }))

    forward = optional(object({
      target_group_arn = string
      stickiness = optional(object({
        enabled  = bool
        type     = string           # e.g., "lb_cookie"
        duration = optional(number) # Duration in seconds for lb_cookie type
      }))
    }))
  })
}

