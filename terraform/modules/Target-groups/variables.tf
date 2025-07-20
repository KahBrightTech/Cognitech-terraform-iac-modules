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
    attachment = object({
      target_id = string
      port      = number
    })
    health_check = object({
      path                = string
      interval            = number
      timeout             = number
      healthy_threshold   = number
      unhealthy_threshold = number
    })
  })
}

