variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

# variable "ngw" {
#   description = "The nat gateway to be associated to the private subnet"
#   type = list(object({
#     name = list(string)
#     # subnet_id     = string
#     # allocation_id = string
#   }))
# }

# variable "eip_ids" {
#   type = map(string)
# }

# variable "primary_subnets" {
#   type = map(string)
# }

# variable "common_tags" {
#   type = map(string)
# }

variable "nat" {
  type = object({
    eip_ids         = map(string)
    primary_subnets = map(string)
    common_tags     = map(string)
  })
}



