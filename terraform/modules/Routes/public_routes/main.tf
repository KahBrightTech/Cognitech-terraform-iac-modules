resource "aws_route_table" "public_route_table" {
  vpc_id = var.vpc_id
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-public"
    }
  )
}
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = var.public_routes.destination_cidr_block
  gateway_id             = var.public_routes.public_gateway_id
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = var.public_routes.subnet_ids
  route_table_id = aws_route_table.public_route_table.id
}


