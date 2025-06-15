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

variable "ec2" {
  description = "EC2 Instance configuration"
  type = object({
    name                        = string
    custom_ami                  = optional(string, null)
    os_release_date             = optional(string, null)
    os_base_packages            = optional(string)
    associate_public_ip_address = optional(bool, false)
    instance_type               = string
    iam_instance_profile        = string
    key_name                    = string
    custom_tags                 = optional(map(string))
    ebs_root_volume = optional(object({
      volume_size           = number
      volume_type           = optional(string, "gp3")
      delete_on_termination = optional(bool, true)
      encrypted             = optional(bool, false)
      kms_key_id            = optional(string, null)
    }), null)
    ebs_device_volume = optional(object({
      name                  = string
      volume_size           = number
      volume_type           = optional(string, "gp3")
      delete_on_termination = optional(bool, true)
      encrypted             = optional(bool, false)
      kms_key_id            = optional(string, null)
    }), null)
    subnet_id          = string
    Schedule_name      = optional(string)
    security_group_ids = list(string)
  })
  default = null
}
