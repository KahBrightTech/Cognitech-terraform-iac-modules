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

variable "vpc_id" {
  description = "The vpc id"
  type        = string
}

variable "tgw_attachments" {
  description = "The transit gateway attachment variables"
  type = object({
    transit_gateway_id   = string
    subnet_ids           = list(string)
    transit_gateway_name = optional(string)
    name                 = optional(string)
  })
}
