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
variable "rule" {
  description = "ALB Listener Rule Configuration"
  type = list(object({

  }))
  default = null
}

