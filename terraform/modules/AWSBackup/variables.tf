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
variable "backup" {
  description = "Backup configuration"
  type = object({
    name       = string
    kms_key_id = optional(string)
    role_name  = optional(string)
    plan = object({
      name = string
      rules = list(object({
        rule_name         = string
        schedule          = string
        start_window      = optional(number)
        completion_window = optional(number)
        lifecycle = optional(object({
          cold_storage_after_days = optional(number)
          delete_after_days       = optional(number)
        }))
        copy_actions = optional(list(object({
          destination_vault_arn = optional(string)
          lifecycle = optional(object({
            cold_storage_after_days = optional(number)
            delete_after_days       = optional(number)
          }))
        })))
      }))
      selection = optional(object({
        selection_name = string
        selection_tags = optional(list(object({
          type  = string
          key   = string
          value = string
        })), [])
        resources = optional(list(string))
      }))
    })
  })
  default = null
}
