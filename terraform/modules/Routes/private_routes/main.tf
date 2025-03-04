resource "aws_route_table" "private_route_table" {
  vpc_id = var.vpc_id
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-private"
    }
  )
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = var.private_routes.destination_cidr_block
  nat_gateway_id         = var.private_routes.nat_gateway_id
}

resource "aws_route_table_association" "private_subnet_association" {
  for_each       = toset(var.private_routes.private_subnet_id)
  subnet_id      = each.value
  route_table_id = aws_route_table.private_route_table.id
}




