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
    name                    = optional(string)
    name_prefix             = optional(string)
    description             = string
    recovery_window_in_days = optional(number)
    policy                  = optional(string)
    value                   = optional(map(string))
  })
  default = null
}


