resource "aws_route" "app_subnet_route" {
  route_table_id         = var.tgw_routes.private_subnet_route_table_id
  destination_cidr_block = var.tgw_routes.shared_vpc_cidr_block
  transit_gateway_id     = var.tgw_routes.transit_gateway_id
}




