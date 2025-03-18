#--------------------------------------------------------------------
# TGW Route - Creates transit gateway attachment
#--------------------------------------------------------------------
resource "aws_ec2_transit_gateway_vpc_attachment" "shared_vpc_attachment" {
  subnet_ids         = var.tgw_attachment.shared_subnet_ids
  transit_gateway_id = var.tgw_attachment.transit_gateway_id
  vpc_id             = var.shared_vpc_id
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-Transit-Gateway-Shared-Attachment"
    }
  )
}

resource "aws_ec2_transit_gateway_vpc_attachment" "App_vpc_attachment" {
  subnet_ids         = var.tgw_attachment.app_subnet_ids
  transit_gateway_id = var.tgw_attachment.transit_gateway_id
  vpc_id             = var.app_vpc_id
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-Transit-Gateway-app-Attachment"
    }
  )
}

resource "aws_route" "app_subnet_route" {
  route_table_id         = var.tgw_routes.app_subnet_route_table_id
  destination_cidr_block = var.tgw_routes.shared_vpc_cidr_block
  transit_gateway_id     = var.tgw_routes.transit_gateway_id
}




