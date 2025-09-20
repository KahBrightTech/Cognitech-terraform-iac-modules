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

variable "datasync" {
  description = "DataSync configuration with all location types and task settings"
  type = object({
    # Common Configuration
    # CloudWatch Log Group Configuration
    create_cloudwatch_log_group   = optional(bool, false)
    cloudwatch_log_group_name     = optional(string)
    cloudwatch_log_retention_days = optional(number, 30)

    # DataSync Task Configuration
    task = optional(object({
      name                     = optional(string)
      source_location_arn      = optional(string)
      destination_location_arn = optional(string)
      cloudwatch_log_group_arn = optional(string)
      options = optional(object({
        atime                          = optional(string)
        bytes_per_second               = optional(number)
        gid                            = optional(string)
        log_level                      = optional(string)
        mtime                          = optional(string)
        overwrite_mode                 = optional(string)
        posix_permissions              = optional(string)
        preserve_deleted_files         = optional(string)
        preserve_devices               = optional(string)
        security_descriptor_copy_flags = optional(string)
        task_queueing                  = optional(string)
        transfer_mode                  = optional(string)
        uid                            = optional(string)
        verify_mode                    = optional(string)
      }))
      schedule_expression = optional(string)
      excludes = optional(list(object({
        filter_type = string
        value       = string
      })))
      includes = optional(list(object({
        filter_type = string
        value       = string
      })))
    }))
    # IAM Role and Policy Configuration
    create_iam_resources = optional(bool, false)
    iam_role = optional(object({
      name                      = string
      description               = optional(string)
      path                      = optional(string, "/")
      assume_role_policy        = optional(string)
      custom_assume_role_policy = optional(bool, true)
      force_detach_policies     = optional(bool, false)
      managed_policy_arns       = optional(list(string))
      max_session_duration      = optional(number, 3600)
      permissions_boundary      = optional(string)
      policy = optional(object({
        name          = optional(string)
        description   = optional(string)
        policy        = optional(string)
        path          = optional(string, "/")
        custom_policy = optional(bool, true)
      }))
    }))
  })
  default = null
}
