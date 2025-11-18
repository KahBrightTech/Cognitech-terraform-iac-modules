#--------------------------------------------------------------------
# Common Variables
#--------------------------------------------------------------------
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

#--------------------------------------------------------------------
# WAF Configuration Variables (All-in-One)
#--------------------------------------------------------------------
variable "waf" {
  description = "Complete WAF configuration object"
  type = object({
    # Basic WAF Configuration
    create_waf                 = optional(bool, true)
    name                       = optional(string, null)
    description                = optional(string, "WAF Web ACL for application protection")
    scope                      = optional(string, "REGIONAL")
    default_action             = optional(string, "allow")
    cloudwatch_metrics_enabled = optional(bool, true)
    sampled_requests_enabled   = optional(bool, true)
    additional_tags            = optional(map(string), {})

    # Managed Rule Groups
    managed_rule_groups = optional(list(object({
      name            = string
      priority        = number
      vendor_name     = string
      exclude_rules   = optional(list(string), [])
      override_action = optional(string, "none")
    })), null)

    # Custom Rules
    custom_rules = optional(list(object({
      name                  = string
      priority              = number
      action                = string
      statement_type        = string
      ip_set_arn            = optional(string)
      country_codes         = optional(list(string))
      rate_limit            = optional(number)
      aggregate_key_type    = optional(string)
      field_to_match        = optional(string)
      positional_constraint = optional(string)
      search_string         = optional(string)
      text_transformation   = optional(string)
    })), [])

    # Rate Limit Rules
    rate_limit_rules = optional(list(object({
      name               = string
      priority           = number
      action             = string
      limit              = number
      aggregate_key_type = string
      scope_down_statement = optional(object({
        type          = string
        country_codes = optional(list(string))
      }))
    })), [])

    # IP Sets
    ip_sets = optional(object({
      create_whitelist   = optional(bool, false)
      create_blacklist   = optional(bool, false)
      ip_address_version = optional(string, "IPV4")
      whitelist_ips      = optional(list(string), [])
      blacklist_ips      = optional(list(string), [])
    }), {})

    # Association
    association = optional(object({
      associate_alb = optional(bool, false)
      alb_arn       = optional(string, null)
    }), {})

    # Logging
    logging = optional(object({
      enabled             = optional(bool, false)
      log_destination_arn = optional(string, null)
      create_log_group    = optional(bool, false)
      log_retention_days  = optional(number, 30)
      redacted_fields     = optional(list(string), [])
      logging_filter = optional(object({
        default_behavior = string
        filters = list(object({
          behavior    = string
          requirement = string
          conditions = list(object({
            type       = string
            action     = optional(string)
            label_name = optional(string)
          }))
        }))
      }), null)
    }), {})
  })

  validation {
    condition     = var.waf.scope == null || contains(["CLOUDFRONT", "REGIONAL"], var.waf.scope)
    error_message = "Scope must be either CLOUDFRONT or REGIONAL."
  }

  validation {
    condition     = var.waf.default_action == null || contains(["allow", "block"], var.waf.default_action)
    error_message = "Default action must be either allow or block."
  }

  validation {
    condition     = var.waf.ip_sets.ip_address_version == null || contains(["IPV4", "IPV6"], var.waf.ip_sets.ip_address_version)
    error_message = "IP address version must be either IPV4 or IPV6."
  }
}
