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

variable "dr_volume_restore" {
  description = "Disaster Recovery Volume Restore configuration"
  type = object({
    name                 = optional(string)
    source_instance_name = string
    target_instance_name = string
    target_az            = string
    device_volumes = list(object({
      device_name = string
      size        = optional(number) # Size in GB, if not specified uses snapshot size
    }))
    restore_volume_tags = map(string)
    account_id          = string
    stop_instance       = optional(bool, true)        # Whether to stop instance during operations
    operation_type      = optional(string, "restore") # "restore" or "resize"
  })
  default = null

  validation {
    condition = var.dr_volume_restore == null ? true : (
      var.dr_volume_restore.device_volumes != null && length(var.dr_volume_restore.device_volumes) > 0
    )
    error_message = "device_volumes must be specified with at least one entry."
  }

  validation {
    condition = var.dr_volume_restore == null ? true : (
      contains(["restore", "resize"], var.dr_volume_restore.operation_type)
    )
    error_message = "operation_type must be either 'restore' or 'resize'."
  }
}
