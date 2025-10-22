#--------------------------------------------------------------------
# TGW Route - Creates transit gateway propagation
#--------------------------------------------------------------------
resource "aws_ec2_transit_gateway_route_table_propagation" "propagation" {
  count                          = var.bypass == false ? 1 : 0
  transit_gateway_attachment_id  = var.tgw_propagation.attachment_id
  transit_gateway_route_table_id = var.tgw_propagation.route_table_id
}







