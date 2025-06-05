resource "aws_route_table" "private_route_table" {
  vpc_id = var.vpc_id
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-private-rt"
    }
  )
}
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = var.private_routes.destination_cidr_block
  nat_gateway_id         = var.private_routes.nat_gateway_id
}

resource "aws_route_table_association" "primary_private_subnet_association" {
  subnet_id      = var.private_routes.primary_subnet_id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "secondary_private_subnet_association" {
  subnet_id      = var.private_routes.secondary_subnet_id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "tertiary_private_subnet_association" {
  count          = var.private_routes.has_tertiary_subnet == true ? 1 : 0
  subnet_id      = var.private_routes.tertiary_subnet_id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "quaternary_private_subnet_association" {
  count          = var.private_routes.has_quaternary_subnet == true ? 1 : 0
  subnet_id      = var.private_routes.quaternary_subnet_id
  route_table_id = aws_route_table.private_route_table.id
}

