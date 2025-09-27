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
# VPC Endpoints Configuration
#--------------------------------------------------------------------
variable "vpc_endpoints" {
  description = "Configuration for VPC Endpoint"
  type = object({
    # Core Configuration
    vpc_id             = string
    service_name       = string
    service_name_short = optional(string)
    endpoint_name      = optional(string)
    endpoint_type      = optional(string)
    auto_accept        = optional(bool)
    # Gateway Endpoint Configuration
    route_table_ids            = optional(list(string), [])
    additional_route_table_ids = optional(list(string))
    # Interface Endpoint Configuration
    subnet_ids          = optional(list(string), [])
    security_group_ids  = optional(list(string), [])
    private_dns_enabled = optional(bool, true)
    dns_record_ip_type  = optional(string)
    # Policy Configuration
    enable_policy   = optional(bool, false)
    policy_document = optional(string)
  })

  validation {
    condition     = var.vpc_endpoints.endpoint_type == null || contains(["Gateway", "Interface"], var.vpc_endpoints.endpoint_type)
    error_message = "Endpoint type must be either 'Gateway' or 'Interface'."
  }

  validation {
    condition     = var.vpc_endpoints.dns_record_ip_type == null || contains(["ipv4", "dualstack", "ipv6"], var.vpc_endpoints.dns_record_ip_type)
    error_message = "DNS record IP type must be one of: ipv4, dualstack, or ipv6."
  }
}

