variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "ssm_parameter" {
  description = "SSM Parameter variables"
  type = object({
    name        = string
    description = string
    type        = string
    value       = string
    tier        = optional(string, "Standard") # Default to Standard if not specified
    overwrite   = optional(bool, false)        # Default to false if not specified
  })
  default = null
}


