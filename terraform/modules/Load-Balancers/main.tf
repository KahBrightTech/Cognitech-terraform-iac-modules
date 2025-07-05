#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#--------------------------------------------------------------------
# Locals
#--------------------------------------------------------------------
locals {
  lb_type_suffix = var.load_balancer.type == "application" ? "alb" : "nlb"
  lb_name        = "${var.common.account_name}-${var.common.region_prefix}-${var.load_balancer.name}-${local.lb_type_suffix}"
}

#-------------------------------------------------------------------------------------------------------------------
# Load Balancer Configuration. Allows creation of Application Load Balancers (ALB) and Network Load Balancers (NLB).
#-------------------------------------------------------------------------------------------------------------------
resource "aws_lb" "main" {
  name                       = var.load_balancer.name
  internal                   = var.load_balancer.internal
  load_balancer_type         = var.load_balancer.type
  security_groups            = var.load_balancer.security_groups
  subnets                    = var.load_balancer.type == "network" && length(var.load_balancer.subnet_mappings) > 0 ? null : var.load_balancer.subnets
  enable_deletion_protection = var.load_balancer.enable_deletion_protection
  # If private IPs specified (only for NLB)
  dynamic "subnet_mapping" {
    for_each = var.load_balancer.type == "network" && length(var.load_balancer.subnet_mappings) > 0 ? var.load_balancer.subnet_mappings : []
    content {
      subnet_id            = subnet_mapping.value.subnet_id
      private_ipv4_address = subnet_mapping.value.private_ipv4_address
    }
  }
  # Optional access logs for ALB
  dynamic "access_logs" {
    for_each = var.load_balancer.type == "application" && var.load_balancer.enable_access_logs ? [1] : []
    content {
      bucket  = var.load_balancer.access_logs_bucket
      prefix  = var.load_balancer.access_logs_prefix
      enabled = true
    }
  }
  tags = merge(var.common.tags, {
    Name = local.lb_name
  })
}


