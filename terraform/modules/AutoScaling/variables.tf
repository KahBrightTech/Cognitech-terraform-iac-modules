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

variable "Autoscaling_group" {
  description = "Auto Scaling configuration"
  type = object({
    name                      = optional(string)
    min_size                  = optional(number)
    max_size                  = optional(number)
    health_check_type         = optional(string)
    health_check_grace_period = optional(number)
    force_delete              = optional(bool)
    desired_capacity          = optional(number)
    subnet_ids                = optional(list(string))
    attach_target_groups      = optional(list(string))
    launch_template = optional(object({
      id      = string
      version = optional(string, "$Latest")
    }))
    timeouts = optional(object({
      delete = optional(string)
    }))
    tags = optional(map(string))
    additional_tags = optional(list(object({
      key                 = string
      value               = string
      propagate_at_launch = optional(bool, true)
    })))
  })
  default = null
}
