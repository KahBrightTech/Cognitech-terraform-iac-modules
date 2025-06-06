resource "aws_ec2_transit_gateway_route_table" "route_table" {
  count              = var.bypass == false ? 1 : 0
  transit_gateway_id = var.tgw_route_table.tgw_id
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.tgw_route_table.name}-tgw-rtb"
  })
}
