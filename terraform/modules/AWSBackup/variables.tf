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
    name        = string
    kms_key_arn = optional(string) # Optional KMS key ARN for encryption
    role_name   = optional(string) # IAM role name for AWS Backup
    plan = object({
      name              = optional(string) # Name of the backup plan
      rule_name         = optional(string) # Name of the backup rule
      schedule          = optional(string) # Default schedule for backups
      start_window      = optional(number) # Start window for backups
      completion_window = optional(number) # Completion window for backups
      lifecycle = optional(object({
        delete_after = optional(number) # Days after which backups are deleted
      }))
      selection = optional(object({
        selection_name = optional(string) # Name of the backup selection
        selection_tags = optional(list(object({
          type  = string # STRINGEQUALS or STRINGNOTEQUALS
          key   = string # Tag key
          value = string # Tag value
        })), [])
        resources = optional(list(string)) # Optional list of resource ARNs
      }))
    })
  })
}
