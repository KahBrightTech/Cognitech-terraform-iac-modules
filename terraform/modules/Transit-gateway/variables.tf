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
    default_route_table_association = enable
    default_route_table_propagation = enable
    auto_accept_shared_attachments  = disable
    dns_support                     = enable
    amazon_side_asn                 = 64512
  })
}


