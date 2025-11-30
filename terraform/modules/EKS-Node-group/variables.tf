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

variable "eks_node_group" {
  description = "EKS node group configuration object."
  type = object({
    cluster_name              = string
    node_group_name           = string
    node_role_arn             = string
    subnet_ids                = list(string)
    desired_size              = number
    max_size                  = number
    min_size                  = number
    instance_types            = list(string)
    ec2_ssh_key               = string
    source_security_group_ids = list(string)
    ami_type                  = optional(string)
    disk_size                 = optional(number, 20)
    labels                    = optional(map(string), {})
    tags                      = optional(map(string), {})
    version                   = optional(string)
    force_update_version      = optional(bool, false)
    capacity_type             = optional(string, "ON_DEMAND")
    launch_template = optional(object({
      name                    = optional(string)
      custom_ami              = optional(string)
      instance_type           = optional(string)
      key_name                = optional(string)
      vpc_security_group_ids  = optional(list(string))
      user_data               = optional(string)
      launch_template_version = optional(string, "$Latest")
      ami_config = object({
        os_release_date = optional(string)
      })
      launch_template_id      = optional(string)
      launch_template_version = optional(string)
    }))
  })
}
