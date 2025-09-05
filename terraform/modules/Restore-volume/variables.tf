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
variable "ebs_restore" {
  description = "EBS Restore configuration"
  type = object({
    instance_id     = string
    os_type         = string               # "windows" or "linux"
    volume_count    = number               # Number of volumes to create
    starting_letter = string               # Starting device letter (e.g., "f" for xvdf)
    volume_size     = optional(number, 10) # Size for all volumes, defaults to 10GB
  })
  default = null
}


