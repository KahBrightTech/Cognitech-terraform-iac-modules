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

variable "tgw_attachments" {
  description = "The transit gateway attachment variables"
  type = object({
    transit_gateway_id                = string
    shared_public_primary_subnet_id   = optional(string)
    shared_public_secondary_subnet_id = optional(string)
    app_private_primary_subnet_id     = optional(string)
    app_private_secondary_subnet_id   = optional(string)
    transit_gateway_name              = optional(string)
    shared_vpc_name                   = optional(string)
  })
}
variable "shared_vpc_id" {
  description = "The shared vpc id"
  type        = string
}

variable "app_vpc_id" {
  description = "The app vpc id"
  type        = string
}
