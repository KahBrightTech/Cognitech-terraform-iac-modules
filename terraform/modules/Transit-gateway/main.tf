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

#--------------------------------------------------------------------
# Creates RAM Share for AWS Resources
#--------------------------------------------------------------------

resource "aws_ram_resource_share" "main" {
  count = var.transit_gateway.ram.enabled ? 1 : 0

  name                      = var.transit_gateway.ram.share_name
  allow_external_principals = var.transit_gateway.ram.allow_external_principals

  tags = merge(
    var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.transit_gateway.ram.share_name}"
  })
}

#--------------------------------------------------------------------
# Creates RAM Share Associations
#--------------------------------------------------------------------
resource "aws_ram_principal_association" "main" {
  count = var.transit_gateway.ram.enabled && length(var.transit_gateway.ram.principals) > 0 ? length(var.transit_gateway.ram.principals) : 0

  principal          = var.transit_gateway.ram.principals[count.index]
  resource_share_arn = aws_ram_resource_share.main[0].arn

  depends_on = [aws_ram_resource_share.main]
}

#--------------------------------------------------------------------
# Creates RAM Resource Associations
#--------------------------------------------------------------------

resource "aws_ram_resource_association" "main" {
  count = var.transit_gateway.ram.enabled ? 1 : 0

  resource_arn       = aws_ec2_transit_gateway.main.arn
  resource_share_arn = aws_ram_resource_share.main[0].arn

  depends_on = [aws_ram_resource_share.main, aws_ec2_transit_gateway.main]
}

