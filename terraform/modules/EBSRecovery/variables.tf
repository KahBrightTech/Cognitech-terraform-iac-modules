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
    restore_volume_tags  = map(string)
    account_id           = string
  })
  default = null
}
