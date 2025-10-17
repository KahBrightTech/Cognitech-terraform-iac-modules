variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
    region        = string
  })
}

variable "transit_gateway" {
  description = "The transit gateway variables"
  type = object({
    name                            = string
    default_route_table_association = string
    default_route_table_propagation = string
    auto_accept_shared_attachments  = string
    dns_support                     = string
    amazon_side_asn                 = number
    vpc_name                        = string
    ram = optional(object({
      enabled                   = optional(bool, false)
      share_name                = optional(string, "transit-gateway-share")
      allow_external_principals = optional(bool, false)
      principals                = optional(list(string), [])
    }))
  })
}


