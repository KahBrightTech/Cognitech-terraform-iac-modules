variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}


variable "iam_user" {
  description = "IAM User configuration"
  type = object({
    name                 = string
    description          = optional(string)
    path                 = optional(string)
    permissions_boundary = optional(string)
    force_destroy        = optional(bool, false)
    groups               = optional(list(string))
    regions              = optional(list(string))
    notifications_email  = string
    user_type            = optional(string, "standard") # standard or service-linked
    create_access_key    = optional(bool, true)         # Whether to create access keys for this user
    secrets_manager = optional(object({
      recovery_window_in_days = optional(number, 30)
      description             = optional(string, null)
    }), {})
    policy = optional(object({
      name        = string
      description = optional(string)
      policy      = string
    }))
  })
  default = null
}

