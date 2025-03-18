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
    default_route_table_association = true
    default_route_table_propagation = true
    auto_accept_shared_attachments  = false
    dns_support                     = true
    amazon_side_asn                 = 64512
  })
}


