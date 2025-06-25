variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "dns_record" {
  description = "The Route 53 records to create"
  type = object({
    name           = string
    zone_id        = string
    type           = string
    ttl            = optional(number, 60)
    records        = optional(list(string))
    set_identifier = optional(string)
    weight         = optional(number)
  })
  default = null
}

