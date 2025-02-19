variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

# variable "eip" {
#   description = "The public subnet to e associated to the elastic ip"
#   type = object({
#     name = list(string)
#   })
# }

variable "primary_subnets" {
  description = "The public subnets to be associated to the elastic ip"
  type        = map(string)
}
