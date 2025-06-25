variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "dns_alias" {
  description = "The Route 53  alias records to create"
  type = object({
    name    = string
    zone_id = optional(string)
    alias = object({
      name                   = string
      zone_id                = optional(string)
      evaluate_target_health = optional(bool, false)
    })
  })
  default = null
}

