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
    name               = string
    port               = number
    protocol           = string
    preserve_client_ip = optional(bool)
    target_type        = optional(string, "instance") # e.g., "instance", "ip", "lambda"
    tags               = optional(map(string))
    vpc_id             = string
    attachments = optional(list(object({
      target_id = string
      port      = number
    })))
    stickiness = optional(object({
      enabled         = bool
      type            = string           # e.g., "lb_cookie"
      cookie_duration = optional(number) # Duration in seconds for lb_cookie type
      cookie_name     = optional(string)
    }))
    health_check = object({
      protocol = optional(string)
      port     = optional(number)
      path     = optional(string)
      matcher  = optional(string)
    })
  })
  default = null
}
