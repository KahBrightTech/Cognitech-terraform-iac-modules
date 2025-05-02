variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "secrets_manager" {
  description = "Secrets Manager variables"
  type = object({
    name                    = string
    description             = string
    recovery_window_in_days = optional(number)
    policy                  = optional(string)
    value                   = optional(string)
    record_folder_uid       = optional(string)
  })
  default = null
}

