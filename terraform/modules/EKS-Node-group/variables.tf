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
      id      = string
      version = optional(string, "$Latest")
    }))
  })
}
