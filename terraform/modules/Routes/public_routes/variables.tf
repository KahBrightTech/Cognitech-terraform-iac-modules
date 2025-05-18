variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "public_routes" {
  description = "The routes and route tables to be created"
  type = object({
    public_gateway_id      = optional(string)
    destination_cidr_block = string
    subnet_ids             = list(string)
  })
}
variable "vpc_id" {
  description = "The vpc id"
  type        = string
}

# variable "public_routes" {
#   description = "The routes and route tables to be created"
#   type = object({
#     public_gateway_id      = optional(string)
#     destination_cidr_block = string
#     primary_subnet_id      = optional(string)
#     secondary_subnet_id    = optional(string)
#     tertiary_subnet_id     = optional(string)
#     has_tertiary_subnet    = optional(bool, false)
#     quaternary_subnet_id   = optional(string)
#     has_quaternary_subnet  = optional(bool, false)
#   })
# }
