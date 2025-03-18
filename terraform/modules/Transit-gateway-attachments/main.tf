#--------------------------------------------------------------------
# TGW Route - Creates transit gateway attachment
#--------------------------------------------------------------------
resource "aws_ec2_transit_gateway_vpc_attachment" "shared_vpc_attachment" {
  subnet_ids         = var.tgw_attachment.shared_subnet_ids
  transit_gateway_id = var.tgw_attachment.transit_gateway_id
  vpc_id             = var.shared_vpc_id
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-tgw-shared-attachment"
    }
  )
}

resource "aws_ec2_transit_gateway_vpc_attachment" "App_vpc_attachment" {
  subnet_ids         = var.tgw_attachment.app_subnet_ids
  transit_gateway_id = var.tgw_attachment.transit_gateway_id
  vpc_id             = var.app_vpc_id
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-tgw-app-attachment"
    }
  )
}





