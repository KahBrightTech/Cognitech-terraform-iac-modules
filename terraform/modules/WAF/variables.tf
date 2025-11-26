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
    name                       = optional(string, null)
    description                = optional(string, "WAF Web ACL for application protection")
    scope                      = optional(string, "REGIONAL")
    default_action             = optional(string, "allow")
    cloudwatch_metrics_enabled = optional(bool, true)
    rule_file                  = optional(string)
    sampled_requests_enabled   = optional(bool, true)

    # Custom Rules
    custom_rules = optional(list(object({
      name                  = string
      priority              = number
      action                = string
      statement_type        = string
      country_codes         = optional(list(string))
      rate_limit            = optional(number)
      aggregate_key_type    = optional(string)
      field_to_match        = optional(string)
      header_name           = optional(string)
      positional_constraint = optional(string)
      search_string         = optional(string)
      text_transformation   = optional(string, "NONE")
      ip_set_arn            = optional(string)
    })))

    # Rule Group References (for custom rule groups)
    rule_group_references = optional(list(object({
      name            = string
      priority        = number
      arn             = string
      override_action = optional(string, "none")
    })))

    # Association
    association = optional(object({
      associate_alb = optional(bool, false)
      alb_arns      = optional(list(string))
      web_acl_arn   = optional(string)
    }))

    # Logging
    logging = optional(object({
      enabled             = optional(bool, false)
      log_destination_arn = optional(string)
      create_log_group    = optional(bool)
      log_retention_days  = optional(number, 30)
      redacted_fields     = optional(list(string))
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
      }))
    }))
  })

  validation {
    condition     = var.waf.scope == null || contains(["CLOUDFRONT", "REGIONAL"], var.waf.scope)
    error_message = "Scope must be either CLOUDFRONT or REGIONAL."
  }

  validation {
    condition     = var.waf.default_action == null || contains(["allow", "block"], var.waf.default_action)
    error_message = "Default action must be either allow or block."
  }

}
