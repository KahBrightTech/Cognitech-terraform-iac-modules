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

variable "event" {
  description = "EventBridge configuration object."
  type = object({
    event_bus_name   = string
    rule_name        = string
    event_pattern    = string
    rule_description = optional(string, "")
    rule_enabled     = optional(bool, true)
    target_arn       = string
    tags             = optional(map(string), {})
  })
}
