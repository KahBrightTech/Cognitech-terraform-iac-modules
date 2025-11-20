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
    additional_tags            = optional(map(string))

    # IP Sets (New Structure)
    ip_sets = optional(list(object({
      create             = optional(bool, true)
      name               = optional(string)
      description        = optional(string)
      type               = optional(string, "custom")
      ip_address_version = optional(string, "IPV4")
      addresses          = list(string)
    })), [])

    # Rule Groups
    rule_groups = optional(list(object({
      create      = optional(bool, true)
      name        = optional(string)
      description = optional(string)
      capacity    = number
      rules = list(object({
        name                  = string
        priority              = number
        action                = string
        statement_type        = string
        ip_set_arn            = optional(string)
        country_codes         = optional(list(string))
        rate_limit            = optional(number)
        aggregate_key_type    = optional(string)
        field_to_match        = optional(string)
        header_name           = optional(string)
        positional_constraint = optional(string)
        search_string         = optional(string)
        text_transformation   = optional(string, "NONE")
        comparison_operator   = optional(string)
        size                  = optional(number)
      }))
    })))
    rule_group_files = optional(list(string))

    # Rule Group References
    rule_group_references = optional(list(object({
      name            = string
      priority        = number
      rule_group_key  = optional(string) # Key from rule_groups created in this module
      rule_group_arn  = optional(string) # ARN of external rule group
      override_action = optional(string, "none")
    })))


    # Managed Rule Groups
    managed_rule_groups = optional(list(object({
      name            = string
      priority        = number
      vendor_name     = optional(string, "AWS")
      exclude_rules   = optional(list(string))
      override_action = optional(string, "none")
    })))

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
      header_name           = optional(string)
      positional_constraint = optional(string)
      search_string         = optional(string)
      text_transformation   = optional(string, "NONE")
    })))

    # Association
    association = optional(object({
      associate_alb = optional(bool, false)
      alb_arn       = optional(string)
    }))

    # Logging
    logging = optional(object({
      enabled             = optional(bool, false)
      log_destination_arn = optional(string, null)
      create_log_group    = optional(bool, false)
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

    # JSON Rule Files
    rule_files = optional(list(string))
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
    condition = var.waf.ip_sets == null || alltrue([
      for ip_set in var.waf.ip_sets :
      ip_set.ip_address_version == null || contains(["IPV4", "IPV6"], ip_set.ip_address_version)
    ])
    error_message = "IP address version must be either IPV4 or IPV6 for all IP sets."
  }

  validation {
    condition = var.waf.rule_group_references == null || alltrue([
      for ref in var.waf.rule_group_references :
      (ref.rule_group_key != null && ref.rule_group_arn == null) ||
      (ref.rule_group_key == null && ref.rule_group_arn != null)
    ])
    error_message = "Each rule group reference must specify exactly one of rule_group_key (for internal rule groups) or rule_group_arn (for external rule groups)."
  }


}
