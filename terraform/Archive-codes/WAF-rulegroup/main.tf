
#--------------------------------------------------------------------
# Data Sources
#--------------------------------------------------------------------
data "aws_region" "current" {}

#--------------------------------------------------------------------
# Locals
#--------------------------------------------------------------------
locals {
  json_rules = var.rule_group != null && var.rule_group.rule_group_files != null && length(var.rule_group.rule_group_files) > 0 ? flatten([
    for file_path in var.rule_group.rule_group_files :
    jsondecode(file(file_path)).rules
  ]) : []

  rule_group = var.rule_group != null ? merge(
    var.rule_group,
    {
      rules = length(local.json_rules) > 0 ? [
        for rule in local.json_rules : {
          name                  = rule.name
          priority              = rule.priority
          action                = rule.action
          statement_type        = rule.statement_type
          ip_set_arn            = try(rule.ip_set_arn, null)
          country_codes         = try(rule.country_codes, null)
          rate_limit            = try(rule.rate_limit, null)
          aggregate_key_type    = try(rule.aggregate_key_type, null)
          field_to_match        = try(rule.field_to_match, null)
          header_name           = try(rule.header_name, null)
          positional_constraint = try(rule.positional_constraint, null)
          search_string         = try(rule.search_string, null)
          text_transformation   = try(rule.text_transformation, "NONE")
          comparison_operator   = try(rule.comparison_operator, null)
          size                  = try(rule.size, null)
        }
      ] : coalesce(var.rule_group.rules, [])
    }
  ) : null
} #--------------------------------------------------------------------
# Rule Groups
#--------------------------------------------------------------------
resource "aws_wafv2_rule_group" "rule_group" {
  count = local.rule_group != null ? 1 : 0

  name        = "${var.common.account_name_abr}-${var.common.region_prefix}-${local.rule_group.name}-rulegroup"
  description = local.rule_group.description != null ? local.rule_group.description : "WAF Rule Group - ${local.rule_group.name}"
  scope       = var.scope
  capacity    = local.rule_group.capacity

  dynamic "rule" {
    for_each = local.rule_group.rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? [1] : []
          content {}
        }

        dynamic "block" {
          for_each = rule.value.action == "block" ? [1] : []
          content {}
        }

        dynamic "count" {
          for_each = rule.value.action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        dynamic "ip_set_reference_statement" {
          for_each = rule.value.statement_type == "ip_set" ? [1] : []
          content {
            arn = rule.value.ip_set_arn
          }
        }

        dynamic "geo_match_statement" {
          for_each = rule.value.statement_type == "geo_match" ? [1] : []
          content {
            country_codes = rule.value.country_codes
          }
        }

        dynamic "rate_based_statement" {
          for_each = rule.value.statement_type == "rate_limit" ? [1] : []
          content {
            limit              = rule.value.rate_limit
            aggregate_key_type = rule.value.aggregate_key_type
          }
        }

        dynamic "byte_match_statement" {
          for_each = rule.value.statement_type == "byte_match" ? [1] : []
          content {
            field_to_match {
              dynamic "uri_path" {
                for_each = rule.value.field_to_match == "uri_path" ? [1] : []
                content {}
              }

              dynamic "query_string" {
                for_each = rule.value.field_to_match == "query_string" ? [1] : []
                content {}
              }

              dynamic "body" {
                for_each = rule.value.field_to_match == "body" ? [1] : []
                content {}
              }

              dynamic "single_header" {
                for_each = rule.value.field_to_match == "single_header" ? [1] : []
                content {
                  name = rule.value.header_name
                }
              }
            }

            positional_constraint = rule.value.positional_constraint
            search_string         = rule.value.search_string

            text_transformation {
              priority = 1
              type     = rule.value.text_transformation
            }
          }
        }

        dynamic "sqli_match_statement" {
          for_each = rule.value.statement_type == "sqli_match" ? [1] : []
          content {
            field_to_match {
              dynamic "uri_path" {
                for_each = rule.value.field_to_match == "uri_path" ? [1] : []
                content {}
              }

              dynamic "query_string" {
                for_each = rule.value.field_to_match == "query_string" ? [1] : []
                content {}
              }

              dynamic "body" {
                for_each = rule.value.field_to_match == "body" ? [1] : []
                content {}
              }

              dynamic "single_header" {
                for_each = rule.value.field_to_match == "single_header" ? [1] : []
                content {
                  name = rule.value.header_name
                }
              }
            }

            text_transformation {
              priority = 1
              type     = rule.value.text_transformation
            }
          }
        }

        dynamic "xss_match_statement" {
          for_each = rule.value.statement_type == "xss_match" ? [1] : []
          content {
            field_to_match {
              dynamic "uri_path" {
                for_each = rule.value.field_to_match == "uri_path" ? [1] : []
                content {}
              }

              dynamic "query_string" {
                for_each = rule.value.field_to_match == "query_string" ? [1] : []
                content {}
              }

              dynamic "body" {
                for_each = rule.value.field_to_match == "body" ? [1] : []
                content {}
              }

              dynamic "single_header" {
                for_each = rule.value.field_to_match == "single_header" ? [1] : []
                content {
                  name = rule.value.header_name
                }
              }
            }

            text_transformation {
              priority = 1
              type     = rule.value.text_transformation
            }
          }
        }

        dynamic "size_constraint_statement" {
          for_each = rule.value.statement_type == "size_constraint" ? [1] : []
          content {
            field_to_match {
              dynamic "uri_path" {
                for_each = rule.value.field_to_match == "uri_path" ? [1] : []
                content {}
              }

              dynamic "query_string" {
                for_each = rule.value.field_to_match == "query_string" ? [1] : []
                content {}
              }

              dynamic "body" {
                for_each = rule.value.field_to_match == "body" ? [1] : []
                content {}
              }

              dynamic "single_header" {
                for_each = rule.value.field_to_match == "single_header" ? [1] : []
                content {
                  name = rule.value.header_name
                }
              }
            }

            comparison_operator = rule.value.comparison_operator
            size                = rule.value.size

            text_transformation {
              priority = 1
              type     = rule.value.text_transformation
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = local.rule_group.name
    sampled_requests_enabled   = true
  }

  tags = merge(var.common.tags,
    {
      Name = local.rule_group.name
    }
  )
}
