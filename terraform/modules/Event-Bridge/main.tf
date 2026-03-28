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


