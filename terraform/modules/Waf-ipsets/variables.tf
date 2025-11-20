#--------------------------------------------------------------------
# Common Variables
#--------------------------------------------------------------------
variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global           = bool
    tags             = map(string)
    account_name     = string
    region_prefix    = string
    account_name_abr = optional(string)
  })
}

#--------------------------------------------------------------------
# IP Set Configuration Variables
#--------------------------------------------------------------------
variable "ip_set" {
  description = "Configuration for a single WAF IP set"
  type = object({
    # Basic Configuration
    name               = string
    description        = optional(string, null)
    scope              = optional(string, "REGIONAL")
    ip_address_version = optional(string, "IPV4")
    addresses          = list(string)
    additional_tags    = optional(map(string), {})
  })

  validation {
    condition     = var.ip_set.scope == null || contains(["CLOUDFRONT", "REGIONAL"], var.ip_set.scope)
    error_message = "Scope must be either CLOUDFRONT or REGIONAL."
  }

  validation {
    condition     = var.ip_set.ip_address_version == null || contains(["IPV4", "IPV6"], var.ip_set.ip_address_version)
    error_message = "IP address version must be either IPV4 or IPV6."
  }

  validation {
    condition     = length(var.ip_set.addresses) > 0
    error_message = "IP set must contain at least one IP address."
  }
}
