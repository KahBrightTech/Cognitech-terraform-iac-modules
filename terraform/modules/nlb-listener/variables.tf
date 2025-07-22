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
variable "nlb_listener" {
  description = "Network Load Balancer listener configuration"
  type = object({
    name            = string
    nlb_arn         = string
    action          = optional(string, "forward")
    port            = number
    protocol        = string
    ssl_policy      = optional(string)
    certificate_arn = optional(string)
    vpc_id          = string
    sni_certificates = optional(list(object({
      domain_name     = optional(string)
      certificate_arn = optional(string)
    })))
    target_group = optional(object({
      name     = optional(string)
      port     = optional(number)
      protocol = optional(string)
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
      health_check = object({
        enabled  = optional(bool, true)
        protocol = optional(string)
        port     = optional(number)
        path     = optional(string)
        matcher  = optional(string, "200")
      })
    }))
  })
  default = null
}

