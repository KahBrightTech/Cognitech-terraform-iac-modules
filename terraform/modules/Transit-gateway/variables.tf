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
    default_route_table_association = bool
    default_route_table_propagation = bool
    auto_accept_shared_attachments  = bool
    dns_support                     = bool
    amazon_side_asn                 = number
  })
}


