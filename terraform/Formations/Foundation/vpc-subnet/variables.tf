variable "common" {
  description = "Common variables used by all resources"
  type = object({
    golbal        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
  default = null
}

variable "vpc" {
  description = "The vpc to be created"
  type = object({
    name       = string
    cidr_block = string
  })
  default = null
}
