variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "public_subnets" {
  description = "The public subnet variables"
  type = object({
    name                         = string
    primary_availability_zone    = optional(string)
    primary_cidr_block           = string
    secondary_availability_zone  = optional(string)
    secondary_cidr_block         = optional(string)
    tertiary_availability_zone   = optional(string)
    tertiary_cidr_block          = optional(string)
    quaternary_availability_zone = optional(string)
    quaternary_cidr_block        = optional(string)
    subnet_type                  = optional(string)
    vpc_name                     = optional(string)
  })
}

variable "vpc_id" {
  description = "The vpc id"
  type        = string
}
