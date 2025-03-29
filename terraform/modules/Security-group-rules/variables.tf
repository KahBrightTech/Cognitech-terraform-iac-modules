variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "security_group" {
  description = "The vpc security group rules"
  type = object({
    security_group_id = string # This will be the ID of the security group created
    egress_rules = optional(list(object({
      key          = string
      cidr_ipv4    = optional(string)
      cidr_ipv6    = optional(string)
      description  = optional(string)
      from_port    = optional(string)
      to_port      = optional(string)
      ip_protocol  = optional(string)
      target_sg_id = optional(string)
      cidr_blocks  = list(string)
      description  = string
    })))
    ingress_rules = optional(list(object({
      key          = string
      cidr_ipv4    = optional(string)
      cidr_ipv6    = optional(string)
      description  = optional(string)
      from_port    = optional(string)
      to_port      = optional(string)
      ip_protocol  = optional(string)
      source_sg_id = optional(string)
      description  = string
    })))
  })
  default = null
}

