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

variable "tgw_attachments" {
  description = "The transit gateway route variables"
  type = object({
    transit_gateway_id        = string
    shared_subnet_ids         = optional(list(string))
    app_subnet_ids            = optional(list(string))
    app_subnet_route_table_id = optional(string)
    shared_vpc_cidr_block     = optional(string)

  })
}
variable "shared_vpc_id" {
  description = "The shared vpc id"
  type        = string
}

variable "app_vpc_id" {
  description = "The app vpc id"
  type        = string
}
