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
  description = "The vpc security group"
  type = object({
    name        = optional(string)
    name_prefix = optional(string)
    vpc_id      = optional(string)
    description = optional(string)
    vpc_name    = string
    security_group_egress_rules = optional(list(object({
      description     = optional(string)
      from_port       = optional(number)
      to_port         = optional(number)
      protocol        = optional(string)
      security_groups = optional(list(string))
      cidr_blocks     = list(string)
      self            = optional(bool, false)
    })))
    security_group_ingress_rules = optional(list(object({
      description     = optional(string)
      from_port       = optional(number)
      to_port         = optional(number)
      protocol        = optional(string)
      security_groups = optional(list(string))
      cidr_blocks     = list(string)
      self            = optional(bool, false)
    })))
  })
  default = null
}
