resource "aws_ec2_transit_gateway_route" "route" {
  count                          = var.bypass == false ? 1 : 0
  blackhole                      = var.tgw_routes.blackhole
  destination_cidr_block         = var.tgw_routes.destination_cidr_block
  transit_gateway_attachment_id  = var.tgw_routes.attachment_id
  transit_gateway_route_table_id = var.tgw_routes.route_table_id
}
