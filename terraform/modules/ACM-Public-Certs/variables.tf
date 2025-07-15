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
variable "certificate" {
  description = "ACM Certificate configuration"
  type = object({
    name              = string
    domain_name       = string
    validation_method = string # "DNS" or "EMAIL"
    zone_name         = string # Route53 zone name for DNS validation
  })
}


