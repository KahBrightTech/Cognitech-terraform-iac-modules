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
variable "certificate" {
  description = "ACM Certificate configuration"
  type = object({
    name                      = string
    domain_name               = string
    validation_method         = string # "DNS" or "EMAIL"
    zone_name                 = string # Route53 zone name for DNS validation
    subject_alternative_names = optional(list(string), [])
    secrets_manager = optional(object({
      enabled                 = optional(bool, false)
      name                    = optional(string)
      description             = optional(string, "Metadata for ACM public certificate")
      kms_key_id              = optional(string)
      recovery_window_in_days = optional(number, 7)
    }))
  })
}

variable "secrets_manager" {
  description = "Optional Secrets Manager settings to publish certificate metadata for downstream consumers. ACM-issued private keys are not exportable. Deprecated in favor of certificate.secrets_manager."
  type = object({
    enabled                 = optional(bool, false)
    name                    = optional(string)
    description             = optional(string, "Metadata for ACM public certificate")
    kms_key_id              = optional(string)
    recovery_window_in_days = optional(number, 7)
  })
  default = {}
}


