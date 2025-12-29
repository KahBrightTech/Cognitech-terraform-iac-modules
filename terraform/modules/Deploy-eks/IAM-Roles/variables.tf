variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global           = bool
    tags             = map(string)
    account_name     = string
    region_prefix    = string
    account_name_abr = optional(string, "")
  })
}

variable "iam_role" {
  description = "IAM Role configuration"
  type = object({
    key                       = string
    name                      = string
    description               = optional(string)
    path                      = optional(string, "/")
    assume_role_policy        = optional(string)
    custom_assume_role_policy = optional(bool, true)
    force_detach_policies     = optional(bool, false)
    managed_policy_arns       = optional(list(string))
    max_session_duration      = optional(number, 3600)
    permissions_boundary      = optional(string)
    create_custom_policy      = optional(bool, true)
    policy = optional(object({
      name          = optional(string)
      description   = optional(string)
      policy        = optional(string)
      path          = optional(string, "/")
      custom_policy = optional(bool, true)
    }))
  })
  default = null
}
