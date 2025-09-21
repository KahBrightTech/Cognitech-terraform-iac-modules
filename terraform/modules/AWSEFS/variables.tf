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

variable "efs" {
  description = "Configuration for EFS file system"
  type = object({
    name                            = string
    creation_token                  = string
    performance_mode                = optional(string, "generalPurpose")
    throughput_mode                 = optional(string, "bursting")
    provisioned_throughput_in_mibps = optional(number)
    encrypted                       = optional(bool, true)
    kms_key_id                      = optional(string)
    subnet_ids                      = list(string)
    security_group_ids              = list(string)

    lifecycle_policy = optional(object({
      transition_to_ia                    = optional(string)
      transition_to_primary_storage_class = optional(string)
    }))

    access_points = optional(map(object({
      name = string
      posix_user = optional(object({
        gid            = number
        uid            = number
        secondary_gids = optional(list(number))
      }))
      root_directory = optional(object({
        path = optional(string, "/")
        creation_info = optional(object({
          owner_gid   = number
          owner_uid   = number
          permissions = string
        }))
      }))
      tags = optional(map(string), {})
    })), {})

    tags = optional(map(string), {})
  })

  validation {
    condition     = contains(["generalPurpose", "maxIO"], var.efs.performance_mode)
    error_message = "Performance mode must be either 'generalPurpose' or 'maxIO'."
  }

  validation {
    condition     = contains(["bursting", "provisioned"], var.efs.throughput_mode)
    error_message = "Throughput mode must be either 'bursting' or 'provisioned'."
  }

  validation {
    condition     = var.efs.throughput_mode != "provisioned" || var.efs.provisioned_throughput_in_mibps != null
    error_message = "When throughput_mode is 'provisioned', provisioned_throughput_in_mibps must be specified."
  }
}
