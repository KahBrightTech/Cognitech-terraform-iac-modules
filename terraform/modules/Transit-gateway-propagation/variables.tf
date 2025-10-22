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

variable "bypass" {
  description = "Bypass the creation of the transit gateway association"
  type        = bool
  default     = false
}

variable "tgw_propagation" {
  description = "The transit gateway propagation variables"
  type = object({
    attachment_id  = string
    route_table_id = string
  })
}
