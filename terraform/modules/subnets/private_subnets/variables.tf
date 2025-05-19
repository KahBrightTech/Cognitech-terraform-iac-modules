variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
  default = null
}

variable "private_subnets" {
  description = "The private subnet variables"
  type = object({
    name                           = string
    primary_availabilty_zone       = optional(string)
    primary_availabilty_zone_id    = optional(string)
    primary_cidr_block             = string
    secondary_availabilty_zone     = optional(string)
    secondary_availabilty_zone_id  = optional(string)
    secondary_cidr_block           = optional(string)
    tertiary_availabilty_zone      = optional(string)
    tertiary_availabilty_zone_id   = optional(string)
    tertiary_cidr_block            = optional(string)
    quaternary_availabilty_zone    = optional(string)
    quaternary_availabilty_zone_id = optional(string)
    quaternary_cidr_block          = optional(string)
    subnet_type                    = optional(string)
  })
}

variable "vpc_id" {
  description = "The vpc id"
  type        = string
}
