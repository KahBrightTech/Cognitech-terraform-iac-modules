resource "aws_route" "route" {
  count                  = var.bypass == false ? 1 : 0
  route_table_id         = var.tgw_subnet_route.route_table_id
  destination_cidr_block = var.tgw_subnet_route.cidr_block
  transit_gateway_id     = var.tgw_subnet_route.transit_gateway_id
}
