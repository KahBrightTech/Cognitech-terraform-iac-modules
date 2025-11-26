
#--------------------------------------------------------------------
# Data Sources
#--------------------------------------------------------------------
data "aws_region" "current" {}

#--------------------------------------------------------------------
# Locals
#--------------------------------------------------------------------
locals {
  rule_files = jsondecode(file(var.waf.rule_file))
}

#--------------------------------------------------------------------
# AWS WAF v2 Web ACL
#--------------------------------------------------------------------
resource "aws_wafv2_web_acl" "main" {
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

  # Rule_files Rules
  dynamic "rule" {
    for_each = local.rule_files
    content {
      name     = rule.value.name
      priority = rule.value.priority

      dynamic "action" {
        for_each = rule.value.action != null ? [1] : []
        content {
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
      }
      dynamic "override_action" {
        for_each = rule.value.override_action != null ? [1] : []
        content {
          dynamic "none" {
            for_each = rule.value.override_action == "none" ? [1] : []
            content {}
          }

          dynamic "count" {
            for_each = rule.value.override_action == "count" ? [1] : []
            content {}
          }
        }
      }

      statement {
        dynamic "geo_match_statement" {
          for_each = rule.value.statement_type == "geo_match" ? [1] : []
          content {
            country_codes = rule.value.country_codes
          }
        }

        dynamic "ip_set_reference_statement" {
          for_each = rule.value.statement_type == "ip_set" ? [1] : []
          content {
            arn = var.waf.ip_set_arns
          }
        }

        dynamic "managed_rule_group_statement" {
          for_each = rule.value.statement_type == "managed_rule_group" ? [1] : []
          content {
            name        = rule.value.name
            vendor_name = rule.value.vendor_name

            dynamic "rule_action_override" {
              for_each = rule.value.rule_overrides != null ? rule.value.rule_overrides : []
              content {
                name = rule_action_override.value.name
                dynamic "action_to_use" {
                  for_each = rule_action_override.value.action != null ? [1] : []
                  content {
                    dynamic "allow" {
                      for_each = rule_action_override.value.action == "allow" ? [1] : []
                      content {}
                    }

                    dynamic "block" {
                      for_each = rule_action_override.value.action == "block" ? [1] : []
                      content {}
                    }

                    dynamic "count" {
                      for_each = rule_action_override.value.action == "count" ? [1] : []
                      content {}
                    }
                  }
                }
              }
            }

            dynamic "scope_down_statement" {
              for_each = rule.value.scope_downs != null ? [1] : []
              content {
                dynamic "geo_match_statement" {
                  for_each = rule.value.scope_downs.geo_match != null ? [1] : []
                  content {
                    country_codes = rule.value.scope_downs.geo_match.country_codes
                  }
                }
              }
            }
          }
        }
        dynamic "rate_based_statement" {
          for_each = rule.value.statement_type == "rate_based" ? [1] : []
          content {
            limit              = rule.value.rate_limit
            aggregate_key_type = rule.value.aggregate_key_type
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.waf.cloudwatch_metrics_enabled
        metric_name                = var.waf.name
        sampled_requests_enabled   = var.waf.sampled_requests_enabled
      }
    }
  }

  # Custom Rules
  dynamic "rule" {
    for_each = var.waf.custom_rules != null ? var.waf.custom_rules : []
    content {
      name     = rule.value.name
      priority = rule.value.priority

      dynamic "action" {
        for_each = rule.value.action != null ? [1] : []
        content {
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
      }
      dynamic "override_action" {
        for_each = rule.value.override_action != null ? [1] : []
        content {
          dynamic "none" {
            for_each = rule.value.override_action == "none" ? [1] : []
            content {}
          }

          dynamic "count" {
            for_each = rule.value.override_action == "count" ? [1] : []
            content {}
          }
        }
      }

      statement {
        dynamic "geo_match_statement" {
          for_each = rule.value.statement_type == "geo_match" ? [1] : []
          content {
            country_codes = rule.value.country_codes
          }
        }

        dynamic "ip_set_reference_statement" {
          for_each = rule.value.statement_type == "ip_set" ? [1] : []
          content {
            arn = var.waf.ip_set_arns
          }
        }

        dynamic "managed_rule_group_statement" {
          for_each = rule.value.statement_type == "managed_rule_group" ? [1] : []
          content {
            name        = rule.value.name
            vendor_name = rule.value.vendor_name

            dynamic "rule_action_override" {
              for_each = rule.value.rule_overrides != null ? rule.value.rule_overrides : []
              content {
                name = rule_action_override.value.name
                dynamic "action_to_use" {
                  for_each = rule_action_override.value.action != null ? [1] : []
                  content {
                    dynamic "allow" {
                      for_each = rule_action_override.value.action == "allow" ? [1] : []
                      content {}
                    }

                    dynamic "block" {
                      for_each = rule_action_override.value.action == "block" ? [1] : []
                      content {}
                    }

                    dynamic "count" {
                      for_each = rule_action_override.value.action == "count" ? [1] : []
                      content {}
                    }
                  }
                }
              }
            }

            dynamic "scope_down_statement" {
              for_each = rule.value.scope_downs != null ? [1] : []
              content {
                dynamic "geo_match_statement" {
                  for_each = rule.value.scope_downs.geo_match != null ? [1] : []
                  content {
                    country_codes = rule.value.scope_downs.geo_match.country_codes
                  }
                }
              }
            }
          }
        }
        dynamic "rate_based_statement" {
          for_each = rule.value.statement_type == "rate_based" ? [1] : []
          content {
            limit              = rule.value.rate_limit
            aggregate_key_type = rule.value.aggregate_key_type
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = var.waf.custom_rules.cloudwatch_metrics_enabled
        metric_name                = "${var.waf.name}-${rule.value.name}"
        sampled_requests_enabled   = var.waf.custom_rules.sampled_requests_enabled
      }
    }
  }

  # Rule Group References
  dynamic "rule" {
    for_each = var.waf.rule_group_references != null ? var.waf.rule_group_references : []
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

  visibility_config {
    cloudwatch_metrics_enabled = var.waf.cloudwatch_metrics_enabled
    metric_name                = "${var.common.account_name_abr}-${var.common.region_prefix}-${var.waf.name}-waf-metric"
    sampled_requests_enabled   = var.waf.sampled_requests_enabled
  }

  tags = merge(
    var.common.tags,
    {
      Name = "${var.common.account_name_abr}-${var.common.region_prefix}-${var.waf.name}-waf"
    }
  )
}

#--------------------------------------------------------------------
# WAF Association with ALB/CloudFront
#--------------------------------------------------------------------
resource "aws_wafv2_web_acl_association" "main" {
  count        = try(length(var.waf.association.alb_arns), 0)
  resource_arn = var.waf.association.alb_arns[count.index]
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

#--------------------------------------------------------------------
# CloudWatch Log Group for WAF (Optional)
#--------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "waf_log_group" {
  count             = var.waf.logging != null && var.waf.logging.create_log_group ? 1 : 0
  name              = "/aws/wafv2/${var.waf.name}"
  retention_in_days = var.waf.logging.log_retention_days
  tags = merge(
    var.common.tags,
    {
      Name = "/aws/wafv2/${var.waf.name}"
    }
  )
}


#--------------------------------------------------------------------
# WAF Logging Configuration
#--------------------------------------------------------------------
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  count = var.waf.logging != null && var.waf.logging.enabled ? 1 : 0

  resource_arn            = aws_wafv2_web_acl.main.arn
  log_destination_configs = ["${aws_cloudwatch_log_group.waf_log_group[0].arn}:*"]
}