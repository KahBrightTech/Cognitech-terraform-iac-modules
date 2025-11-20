
#--------------------------------------------------------------------
# Data Sources
#--------------------------------------------------------------------
data "aws_region" "current" {}

#--------------------------------------------------------------------
# Locals
#--------------------------------------------------------------------
locals {
  json_rules = length(var.waf.rule_files) > 0 ? flatten([
    for file_path in var.waf.rule_files :
    jsondecode(file(file_path)).rules
  ]) : []
  all_custom_rules = concat(var.waf.custom_rules, local.json_rules)
}

#--------------------------------------------------------------------
# AWS WAF v2 Web ACL
#--------------------------------------------------------------------
resource "aws_wafv2_web_acl" "main" {
  count = var.waf.create_waf ? 1 : 0

  name        = "${var.common.account_name_abr}-${var.common.region_prefix}-${var.waf.name}-waf"
  description = var.waf.description
  scope       = var.waf.scope

  default_action {
    dynamic "allow" {
      for_each = var.waf.default_action == "allow" ? [1] : []
      content {}
    }

    dynamic "block" {
      for_each = var.waf.default_action == "block" ? [1] : []
      content {}
    }
  }

  # Managed Rule Groups
  dynamic "rule" {
    for_each = var.waf.managed_rule_groups
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.override_action == "none" ? [1] : []
          content {}
        }

        dynamic "count" {
          for_each = rule.value.override_action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = rule.value.vendor_name

          dynamic "excluded_rule" {
            for_each = rule.value.exclude_rules
            content {
              name = excluded_rule.value
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

  # Rule Group References
  dynamic "rule" {
    for_each = var.waf.rule_group_references
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.override_action == "none" ? [1] : []
          content {}
        }

        dynamic "count" {
          for_each = rule.value.override_action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        rule_group_reference_statement {
          arn = rule.value.arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }
  }

  # Custom Rules (from variables and JSON files)
  dynamic "rule" {
    for_each = local.all_custom_rules
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
            }

            positional_constraint = rule.value.positional_constraint
            search_string         = rule.value.search_string

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
    cloudwatch_metrics_enabled = var.waf.cloudwatch_metrics_enabled
    metric_name                = "${var.waf.name}-waf-metric"
    sampled_requests_enabled   = var.waf.sampled_requests_enabled
  }

  tags = merge(var.common.tags, var.waf.additional_tags, {
    Name = var.waf.name
  })
}


#--------------------------------------------------------------------
# WAF Association with ALB/CloudFront
#--------------------------------------------------------------------
resource "aws_wafv2_web_acl_association" "main" {
  count = var.waf.association.associate_alb && var.waf.association.alb_arn != null ? 1 : 0

  resource_arn = var.waf.association.alb_arn
  web_acl_arn  = var.waf.association.web_acl_arn
}

#--------------------------------------------------------------------
# WAF Logging Configuration
#--------------------------------------------------------------------
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  count = var.waf.logging.enabled && var.waf.create_waf ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.main[0].arn
  log_destination_configs = [var.waf.logging.log_destination_arn]

  dynamic "redacted_fields" {
    for_each = var.waf.logging.redacted_fields
    content {
      dynamic "uri_path" {
        for_each = redacted_fields.value == "uri_path" ? [1] : []
        content {}
      }

      dynamic "query_string" {
        for_each = redacted_fields.value == "query_string" ? [1] : []
        content {}
      }

      dynamic "single_header" {
        for_each = length(regexall("header_", redacted_fields.value)) > 0 ? [1] : []
        content {
          name = replace(redacted_fields.value, "header_", "")
        }
      }
    }
  }

  dynamic "logging_filter" {
    for_each = var.waf.logging.logging_filter != null ? [1] : []
    content {
      default_behavior = var.waf.logging.logging_filter.default_behavior

      dynamic "filter" {
        for_each = var.waf.logging.logging_filter.filters
        content {
          behavior    = filter.value.behavior
          requirement = filter.value.requirement

          dynamic "condition" {
            for_each = filter.value.conditions
            content {
              dynamic "action_condition" {
                for_each = condition.value.type == "action" ? [1] : []
                content {
                  action = condition.value.action
                }
              }

              dynamic "label_name_condition" {
                for_each = condition.value.type == "label" ? [1] : []
                content {
                  label_name = condition.value.label_name
                }
              }
            }
          }
        }
      }
    }
  }
}

#--------------------------------------------------------------------
# CloudWatch Log Group for WAF (Optional)
#--------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "waf_log_group" {
  count = var.waf.logging.create_log_group ? 1 : 0

  name              = "/aws/wafv2/${var.waf.name}"
  retention_in_days = var.waf.logging.log_retention_days

  tags = merge(var.common.tags, var.waf.additional_tags, {
    Name = "/aws/wafv2/${var.waf.name}"
  })
}
