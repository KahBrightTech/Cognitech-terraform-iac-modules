#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get availability zones for the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get VPC information
data "aws_vpc" "selected" {
  id = var.vpc_endpoints.vpc_id
}

#--------------------------------------------------------------------
# Local Variables
#--------------------------------------------------------------------
locals {
  endpoint_name = var.vpc_endpoints.endpoint_name != null ? var.vpc_endpoints.endpoint_name : "${var.common.account_name}-${var.common.region_prefix}-${var.vpc_endpoints.service_name_short}-vpc-endpoint"

  # Determine endpoint type based on service name if not explicitly provided
  service_type = var.vpc_endpoints.endpoint_type != null ? var.vpc_endpoints.endpoint_type : (
    contains([
      "com.amazonaws.${data.aws_region.current.name}.s3",
      "com.amazonaws.${data.aws_region.current.name}.dynamodb"
    ], var.vpc_endpoints.service_name) ? "Gateway" : "Interface"
  )

  # Common tags
  common_tags = merge(var.common.tags, {
    "Name" = local.endpoint_name
  })
}

#--------------------------------------------------------------------
# VPC Endpoint Policy Document
#--------------------------------------------------------------------
data "aws_iam_policy_document" "vpc_endpoint_policy" {
  count = var.vpc_endpoints.policy_document != null ? 0 : 1

  statement {
    effect = "Allow"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["*"]
    resources = ["*"]
  }
}
#--------------------------------------------------------------------
# AWS VPC Endpoint
#--------------------------------------------------------------------
resource "aws_vpc_endpoint" "main" {
  vpc_id            = var.vpc_endpoints.vpc_id
  service_name      = var.vpc_endpoints.service_name
  vpc_endpoint_type = local.service_type
  auto_accept       = var.vpc_endpoints.auto_accept

  # Gateway endpoint specific configuration
  route_table_ids = local.service_type == "Gateway" ? var.vpc_endpoints.route_table_ids : null

  # Interface endpoint specific configuration
  subnet_ids          = local.service_type == "Interface" ? var.vpc_endpoints.subnet_ids : null
  security_group_ids  = local.service_type == "Interface" ? var.vpc_endpoints.security_group_ids : null
  private_dns_enabled = local.service_type == "Interface" ? var.vpc_endpoints.private_dns_enabled : null
  # Policy configuration
  policy = var.vpc_endpoints.policy_document != null ? var.vpc_endpoints.policy_document : (
    var.vpc_endpoints.enable_policy ? data.aws_iam_policy_document.vpc_endpoint_policy[0].json : null
  )
  # DNS options for Interface endpoints
  dynamic "dns_options" {
    for_each = local.service_type == "Interface" && var.vpc_endpoints.dns_record_ip_type != null ? [1] : []
    content {
      dns_record_ip_type = var.vpc_endpoints.dns_record_ip_type
    }
  }
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.vpc_endpoints.endpoint_name}-${var.vpc_endpoints.endpoint_type}-endpoint"
  })
  lifecycle {
    create_before_destroy = true
  }
}

#--------------------------------------------------------------------
# VPC Endpoint Route Table Associations (for Gateway endpoints)
#--------------------------------------------------------------------
resource "aws_vpc_endpoint_route_table_association" "main" {
  for_each        = local.service_type == "Gateway" && var.vpc_endpoints.additional_route_table_ids != null ? toset(var.vpc_endpoints.additional_route_table_ids) : toset([])
  vpc_endpoint_id = aws_vpc_endpoint.main.id
  route_table_id  = each.value
}
