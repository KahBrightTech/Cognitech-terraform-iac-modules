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
    key          = string
    listener_arn = string
    priority     = optional(number)
    type         = string
    target_groups = list(object({
      arn    = string
      weight = optional(number)
    }))
    conditions = list(object({
      host_headers         = optional(list(string))
      http_request_methods = optional(list(string))
      path_patterns        = optional(list(string))
      source_ips           = optional(list(string))
      http_headers = optional(list(object({
        name   = string
        values = list(string)
      })))
      query_strings = optional(list(object({
        key   = optional(string)
        value = string
      })))
    }))
  }))
  default = null
}

