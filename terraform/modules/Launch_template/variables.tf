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
variable "launch_template" {
  description = "Launch Template configuration"
  type = object({
    name             = string
    instance_profile = optional(string)
    custom_ami       = optional(string)
    ami_config = object({
      os_release_date  = optional(string)
      os_base_packages = optional(string)
    })
    instance_type               = optional(string)
    key_name                    = optional(string)
    associate_public_ip_address = optional(bool)
    vpc_security_group_ids      = optional(list(string))
    tags                        = optional(map(string))
    # network_interfaces = optional(list(object({
    #   security_groups             = optional(list(string))
    #   delete_on_termination       = optional(bool)
    #   associate_public_ip_address = optional(bool)
    # })))
    user_data = optional(string)
  })
  default = null
}


