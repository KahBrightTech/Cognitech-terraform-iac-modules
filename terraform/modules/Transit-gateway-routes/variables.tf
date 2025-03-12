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

variable "tgw_routes" {
  description = "The transit gateway route variables"
  type = object({
    transit_gateway_id = string
    shared_subnet_ids  = optional(list(string))
    app_subnet_ids     = optional(list(string))

  })
}
variable "vpc_id" {
  description = "The vpc id"
  type        = string
}
