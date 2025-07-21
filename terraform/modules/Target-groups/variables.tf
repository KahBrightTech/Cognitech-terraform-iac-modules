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
variable "target_group" {
  description = "Target Group configuration"
  type = object({
    name     = string
    port     = number
    protocol = string
    vpc_id   = string
    attachment = optional(object({
      target_id = string
      port      = number
    }))
    stickiness = optional(object({
      enabled  = bool
      type     = string           # e.g., "lb_cookie"
      duration = optional(number) # Duration in seconds for lb_cookie type
    }))
    health_check = object({
      enabled             = optional(bool, true)
      protocol            = optional(string)
      port                = optional(number)
      path                = optional(string)
      interval            = optional(number)
      timeout             = optional(number)
      healthy_threshold   = optional(number)
      unhealthy_threshold = optional(number)
    })
  })
}

