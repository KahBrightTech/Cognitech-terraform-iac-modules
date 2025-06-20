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

variable "nat_gateway" {
  description = "The nat gateway variables"
  type = object({
    name                  = string
    type                  = string
    subnet_id_primary     = string
    subnet_id_secondary   = optional(string)
    subnet_id_tertiary    = optional(string)
    subnet_id_quaternary  = optional(string)
    has_tertiary_subnet   = optional(bool, false)
    has_quaternary_subnet = optional(bool, false)
    vpc_name              = string
    subnet_name           = string
  })
  validation {
    condition     = var.nat_gateway.type == "public" || var.nat_gateway.type == "private" || var.nat_gateway.type == "unknown"
    error_message = "The nat_gateway type must be either 'public', 'private', or 'unknown"
  }
}

variable "bypass" {
  description = "Bypass the creation of the nat gateway"
  type        = bool
  default     = false

}
