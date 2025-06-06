#--------------------------------------------------------------------
#TWG - Creates a Transit Gateway
#--------------------------------------------------------------------resource "aws_ec2_transit_gateway" "tgw" {
resource "aws_ec2_transit_gateway" "main" {
  description                     = "The main transit gateway for the account"
  amazon_side_asn                 = var.transit_gateway.amazon_side_asn
  default_route_table_association = var.transit_gateway.default_route_table_association
  default_route_table_propagation = var.transit_gateway.default_route_table_propagation
  auto_accept_shared_attachments  = var.transit_gateway.auto_accept_shared_attachments
  dns_support                     = var.transit_gateway.dns_support
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.transit_gateway.vpc_name}-${var.transit_gateway.name}-tgw"
    }
  )
}



