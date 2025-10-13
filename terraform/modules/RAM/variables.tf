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

variable "ram" {
  description = "Configuration for AWS Resource Access Manager (RAM) sharing"
  type = object({
    enabled                   = bool
    share_name                = string
    allow_external_principals = optional(bool, true)
    resource_arns             = list(string)
    principals                = list(string)
  })

  validation {
    condition     = length(var.ram.share_name) > 0
    error_message = "Share name must not be empty."
  }

  validation {
    condition     = !var.ram.enabled || length(var.ram.resource_arns) > 0
    error_message = "At least one resource ARN must be provided when RAM sharing is enabled."
  }

  validation {
    condition     = !var.ram.enabled || length(var.ram.principals) > 0
    error_message = "At least one principal (AWS account ID or organization ARN) must be provided when RAM sharing is enabled."
  }

  validation {
    condition = alltrue([
      for principal in var.ram.principals : can(regex("^(\\d{12}|arn:aws:organizations::[0-9]{12}:organization/o-[a-z0-9]{10,32})$", principal))
    ])
    error_message = "Principals must be valid AWS account IDs (12 digits) or organization ARNs (arn:aws:organizations::account-id:organization/o-xxxxxxxxxx)."
  }
}

