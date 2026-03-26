#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_cloudwatch_event_bus" "this" {
  count = var.event.event_bus_name != null && var.event.event_bus_name != "" && var.event.event_bus_name != "default" ? 1 : 0
  name  = var.event.event_bus_name
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.event.event_bus_name}"
  })
}

resource "aws_cloudwatch_event_rule" "this" {
  name           = var.event.rule_name
  event_bus_name = var.event.event_bus_name != null && var.event.event_bus_name != "" && var.event.event_bus_name != "default" ? aws_cloudwatch_event_bus.this[0].name : "default"
  event_pattern  = var.event.event_pattern
  description    = var.event.rule_description
  is_enabled     = var.event.rule_enabled
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.event.rule_name}"
  })
}

resource "aws_cloudwatch_event_target" "this" {
  rule           = aws_cloudwatch_event_rule.this.name
  event_bus_name = var.event.event_bus_name != null && var.event.event_bus_name != "" && var.event.event_bus_name != "default" ? aws_cloudwatch_event_bus.this[0].name : "default"
  arn            = var.event.target_arn
  # No tags argument for aws_cloudwatch_event_target
}

resource "aws_ecr_replication_configuration" "replication" {
  count = var.ecr.replication_configuration != null ? 1 : 0

  replication_configuration {
    dynamic "rule" {
      for_each = var.ecr.replication_configuration.rules
      content {
        dynamic "destination" {
          for_each = rule.value.destinations
          content {
            region      = destination.value.region
            registry_id = destination.value.registry_id
          }
        }
        dynamic "repository_filter" {
          for_each = rule.value.repository_filter != null ? [rule.value.repository_filter] : []
          content {
            filter      = repository_filter.value.filter
            filter_type = repository_filter.value.filter_type
          }
        }
      }
    }
  }
}

