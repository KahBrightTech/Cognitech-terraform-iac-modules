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
variable "alb_listener" {
  description = "Load Balancer listener configuration"
  type = object({
    alb_arn          = string
    action           = optional(string, "forward")
    port             = number
    protocol         = string
    ssl_policy       = optional(string)
    certificate_arn  = optional(string)
    alt_alb_hostname = optional(string)
    vpc_id           = string
    fixed_response = optional(object({
      content_type = optional(string, "text/plain")
      message_body = optional(string, "Oops! The page you are looking for does not exist.")
      status_code  = optional(string, "200")
    }))
    sni_certificates = optional(list(object({
      domain_name     = optional(string)
      certificate_arn = optional(string)
    })))
    target_group = optional(object({
      name     = optional(string)
      port     = optional(number)
      protocol = optional(string)
      attachment = optional(list(object({
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
        protocol = optional(string)
        port     = optional(number)
        path     = optional(string)
        matcher  = optional(string)
      })
    }))
  })
  default = null
}

