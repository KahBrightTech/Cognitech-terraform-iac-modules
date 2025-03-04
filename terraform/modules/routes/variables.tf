variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "routes" {
  description = "Thhe routes and route tables to be created"
  type = object({
    public_gateway_id      = string
    nat_gateway_id         = string
    destination_cidr_block = string
    primary_subnet_id      = string
    secondary_subnet_id    = optional(string)
    tertiary_subnet_id     = optional(string)
    has_tertiary_subnet    = optional(bool, false)
    private_subnets_id     = list(string)
  })

}
variable "vpc_id" {
  description = "The vpc id"
  type        = string
}
