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
variable "tgw_route_table" {
  description = "The transit gateway route table variables"
  type = object({
    name   = string
    tgw_id = string
  })
}

variable "bypass" {
  description = "Bypass the creation of the transit gateway route table"
  type        = bool
  default     = false

}
