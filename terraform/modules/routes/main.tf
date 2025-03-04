resource "aws_route_table" "public_route_table" {
  vpc_id = var.vpc_id
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-public"
    }
  )
}

resource "aws_route_table" "private_route_table" {
  vpc_id = var.vpc_id
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-private"
    }
  )
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = var.routes.destination_cidr_block
  gateway_id             = var.routes.public_gateway_id
  depends_on             = [aws_internet_gateway.example]
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = var.routes.destination_cidr_block
  nat_gateway_id         = var.routes.nat_gateway_id
  depends_on             = [aws_nat_gateway.example]
}

resource "aws_route_table_association" "primary_public_subnet_association" {
  subnet_id      = var.routes.primary_subnet_id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "secondary_public_subnet_association" {
  subnet_id      = var.routes.secondary_subnet_id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "tertiary_public_subnet_association" {
  count          = var.routes.has_tertiary_subnet == true ? 1 : 0
  subnet_id      = var.routes.tertiary_subnet_id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = var.routes.private_subnet_id
  route_table_id = aws_route_table.private_route_table.id
}

