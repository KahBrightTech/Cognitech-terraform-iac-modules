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

variable "key_pair" {
  description = "Key pair configuration for EC2 instances"
  type = object({
    name = string
  })
  default = null
}
