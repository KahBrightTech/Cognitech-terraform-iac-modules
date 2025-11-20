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
# WAF Rule Group Configuration Variables
#--------------------------------------------------------------------
variable "scope" {
  description = "Specifies whether this is for an AWS CloudFront distribution or for a regional application. Valid values are CLOUDFRONT or REGIONAL"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["CLOUDFRONT", "REGIONAL"], var.scope)
    error_message = "Scope must be either CLOUDFRONT or REGIONAL."
  }
}

variable "rule_group" {
  description = "WAF rule group configuration"
  type = object({
    name             = string
    description      = optional(string)
    capacity         = number
    rule_group_files = optional(list(string), [])
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
  })
  default = null

  validation {
    condition = var.rule_group == null || alltrue([
      for rule in var.rule_group.rules :
      contains(["allow", "block", "count"], rule.action)
    ])
    error_message = "Rule action must be one of: allow, block, count."
  }

  validation {
    condition = var.rule_group == null || alltrue([
      for rule in var.rule_group.rules :
      contains([
        "ip_set", "geo_match", "rate_limit", "byte_match",
        "sqli_match", "xss_match", "size_constraint"
      ], rule.statement_type)
    ])
    error_message = "Statement type must be one of: ip_set, geo_match, rate_limit, byte_match, sqli_match, xss_match, size_constraint."
  }
}