resource "aws_route" "tgw_route" {
  # for_each               = { for idx, route in var.tgw_routes : idx => route }
  route_table_id         = var.tgw_routes.route_table_id
  destination_cidr_block = var.tgw_routes.vpc_cidr_block
  transit_gateway_id     = var.tgw_routes.transit_gateway_id
}




