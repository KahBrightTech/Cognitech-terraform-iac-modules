#--------------------------------------------------------------------
# TGW Route - Creates transit gateway attachment
#--------------------------------------------------------------------
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_attachment" {
  subnet_ids = [
    var.tgw_attachment.primary_subnet_id,
    var.tgw_attachment.secondary_subnet_id
  ]
  transit_gateway_id = var.tgw_attachment.transit_gateway_id
  vpc_id             = var.tgw_attachment.vpc_id
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.tgw_attachments.attachment_name}"
    }
  )
}

# resource "aws_ec2_transit_gateway_vpc_attachment" "App_vpc_attachment" {
#   subnet_ids         = var.tgw_attachment.app_subnet_ids
#   transit_gateway_id = var.tgw_attachment.transit_gateway_id
#   vpc_id             = var.app_vpc_id
#   tags = merge(var.common.tags,
#     {
#       "Name" = "${var.common.account_name}-${var.common.region_prefix}-tgw-app-attachment"
#     }
#   )
# }





