variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "route53_zones" {
  description = "The Route 53 hosted zones to be created"
  type = object({
    name = string
    vpc = optional(object({
      id = string
    }))
    comment       = optional(string, null)
    private_zone  = optional(bool, true)
    force_destroy = optional(bool, true)
  })
  default = null
}

