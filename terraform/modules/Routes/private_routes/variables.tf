variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "private_routes" {
  description = "The routes and route tables to be created"
  type = object({
    nat_gateway_id         = optional(string)
    destination_cidr_block = string
    primary_subnet_id      = string
    secondary_subnet_id    = string
    tertiary_subnet_id     = optional(string)
    quaternary_subnet_id   = optional(string)
    has_tertiary_subnet    = optional(bool, false)
    has_quaternary_subnet  = optional(bool, false)
  })
  default = null
}
variable "vpc_id" {
  description = "The vpc id"
  type        = string
}
