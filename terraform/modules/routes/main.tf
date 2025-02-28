resource "aws_route_table" "public_route_table" {
  vpc_id = var.vpc_id

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = var.vpc_id

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route" "public_route" {
  count                  = var.public_route_count
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = var.public_route_cidrs[count.index]
  gateway_id             = var.public_gateway_id
  depends_on             = [aws_internet_gateway.example]
}

resource "aws_route" "private_route" {
  count                  = var.private_route_count
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = var.private_route_cidrs[count.index]
  nat_gateway_id         = var.nat_gateway_id
  depends_on             = [aws_nat_gateway.example]
}
