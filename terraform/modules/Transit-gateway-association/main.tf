#--------------------------------------------------------------------
# TGW Route - Creates transit gateway association
#--------------------------------------------------------------------
resource "aws_ec2_transit_gateway_route_table_association" "association" {
  count                          = var.bypass == false ? 1 : 0
  transit_gateway_attachment_id  = var.tgw_association.attachment_id
  transit_gateway_route_table_id = var.tgw_association.route_table_id

}







