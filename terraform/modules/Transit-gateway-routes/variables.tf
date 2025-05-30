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
    blackhole              = bool
    destination_cidr_block = string
    attachment_id          = optional(string)
    route_table_id         = string
  })
}

variable "bypass" {
  description = "Bypass the creation of the transit gateway route table"
  type        = bool
  default     = false

}

