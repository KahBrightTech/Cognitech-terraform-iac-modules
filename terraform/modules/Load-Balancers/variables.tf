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

variable "load_balancer" {
  description = "Load Balancer configuration"
  type = object({
    name            = string
    internal        = optional(bool, false)
    type            = string           # "application" or "network"
    lb_type_abr     = optional(string) # "alb" for Application Load Balancer, "nlb" for Network Load Balancer
    security_groups = optional(list(string))
    subnets         = optional(list(string))
    subnet_mappings = optional(list(object({
      subnet_id            = string
      private_ipv4_address = optional(string)
    })))
    enable_deletion_protection = optional(bool, false)
    enable_access_logs         = optional(bool, false)
    access_logs_bucket         = optional(string)
    access_logs_prefix         = optional(string)
  })
  default = null
}
