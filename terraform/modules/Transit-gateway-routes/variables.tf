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
    name               = string
    route_table_id     = string
    vpc_cidr_block     = string
    transit_gateway_id = string
  })
}

# variable "route_table_id" {
#   description = "The id of the route table"
#   type        = string
# }

# variable "vpc_cidr_block" {
#   description = "The cidr block for the destination vpc"
#   type        = string
# }

# variable "transit_gateway_id" {
#   description = "The id of the transit gateway"
#   type        = string
# }
