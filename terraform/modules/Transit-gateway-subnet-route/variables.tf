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
variable "tgw_subnet_route" {
  description = "Subnet routes to the transit gateway"
  type = object({
    route_table_id     = string
    cidr_block         = string
    transit_gateway_id = string
  })
  default = null
}

variable "bypass" {
  description = "Bypass the creation of the transit gateway route table"
  type        = bool
  default     = false
}

