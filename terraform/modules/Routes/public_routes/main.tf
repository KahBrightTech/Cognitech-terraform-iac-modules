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

resource "aws_route_table_association" "primary_public_subnet_association" {
  subnet_id      = var.public_routes.primary_subnet_id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "secondary_public_subnet_association" {
  subnet_id      = var.public_routes.secondary_subnet_id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "tertiary_public_subnet_association" {
  count          = var.public_routes.has_tertiary_subnet == true ? 1 : 0
  subnet_id      = var.public_routes.tertiary_subnet_id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "quaternary_public_subnet_association" {
  count          = var.public_routes.has_quaternary_subnet == true ? 1 : 0
  subnet_id      = var.public_routes.quaternary_subnet_id
  route_table_id = aws_route_table.public_route_table.id
}

