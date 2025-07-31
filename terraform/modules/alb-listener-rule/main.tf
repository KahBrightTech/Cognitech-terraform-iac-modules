#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#-------------------------------------------------------------------------------------------------------------------
# ALB Listener Rule Configuration
#-------------------------------------------------------------------------------------------------------------------

resource "aws_lb_listener_rule" "rule" {
  for_each     = { for rule in var.rule : rule.key => rule }
  listener_arn = each.value.listener_arn
  priority     = each.value.priority
  tags         = var.common.tags

  action {
    type             = each.value.type
    target_group_arn = length(each.value.target_groups) == 1 ? each.value.target_groups[0].arn : null

    dynamic "forward" {
      for_each = each.value.type == "forward" && length(each.value.target_groups) != 1 ? [1] : []
      content {
        dynamic "target_group" {
          for_each = each.value.target_groups
          content {
            arn    = target_group.value["arn"]
            weight = target_group.value["weight"]
          }
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [for rule_condition in each.value.conditions : rule_condition if rule_condition.host_headers != null]
    content {
      host_header {
        values = condition.value["host_headers"]
      }
    }
  }

  dynamic "condition" {
    for_each = [for rule_condition in each.value.conditions : rule_condition if rule_condition.http_request_methods != null]
    content {
      http_request_method {
        values = condition.value["http_request_methods"]
      }
    }
  }

  dynamic "condition" {
    for_each = [for rule_condition in each.value.conditions : rule_condition if rule_condition.path_patterns != null]
    content {
      path_pattern {
        values = condition.value["path_patterns"]
      }
    }
  }

  dynamic "condition" {
    for_each = [for rule_condition in each.value.conditions : rule_condition if rule_condition.source_ips != null]
    content {
      source_ip {
        values = condition.value["source_ips"]
      }
    }
  }

  dynamic "condition" {
    for_each = [for rule_condition in each.value.conditions : rule_condition if rule_condition.http_headers != null]
    content {
      dynamic "http_header" {
        for_each = condition.value["http_headers"]
        content {
          http_header_name = http_header.value["name"]
          values           = http_header.value["values"]
        }
      }
    }
  }

  dynamic "condition" {
    for_each = [for rule_condition in each.value.conditions : rule_condition if rule_condition.query_strings != null]
    content {
      dynamic "query_string" {
        for_each = condition.value["query_strings"]
        content {
          key   = query_string.value["key"]
          value = query_string.value["value"]
        }
      }
    }
  }
}
