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
    name               = optional(string)
    port               = optional(number)
    protocol           = optional(string)
    preserve_client_ip = optional(bool)
    target_type        = optional(string, "instance")
    tags               = optional(map(string))
    vpc_id             = string
    vpc_name_abr       = optional(string)
    attachments = optional(list(object({
      target_id = optional(string)
      port      = optional(number)
    })))
    stickiness = optional(object({
      enabled         = optional(bool)
      type            = optional(string)
      cookie_duration = optional(number)
      cookie_name     = optional(string)
    }))
    health_check = optional(object({
      protocol = optional(string)
      port     = optional(number)
      path     = optional(string)
      matcher  = optional(string)
    }))
  })
  default = null
}
