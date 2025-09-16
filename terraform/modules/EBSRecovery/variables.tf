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
    device_names         = list(string)
    # Option 1: Simple list for backward compatibility
    # device_names         = list(string)
    # Option 2: Map for device name to size mapping
    device_volumes = optional(map(object({
      device_name = string
      size        = optional(number) # Size in GB, if not specified uses snapshot size
    })))
    restore_volume_tags = map(string)
    account_id          = string
  })
  default = null

  validation {
    condition     = var.dr_volume_restore != null ? (var.dr_volume_restore.device_names != null || var.dr_volume_restore.device_volumes != null) : true
    error_message = "Either device_names or device_volumes must be specified."
  }
}
