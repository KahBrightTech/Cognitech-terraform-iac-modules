#--------------------------------------------------------------------
# Route table for public subnets
#--------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = var.vpc_id
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-primary-public-rt"
    }
  )
}

resource "aws_route_table" "public_secondary" {
  vpc_id = var.vpc_id
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-secondary-public-rt"
    }
  )
}

resource "aws_route_table" "public_tertiary" {
  count  = var.public_routes.has_tertiary_subnet == true ? 1 : 0
  vpc_id = var.vpc_id
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-tertiary-public-rt"
    }
  )
}

resource "aws_route_table" "public_quaternary" {
  count  = var.public_routes.has_quaternary_subnet == true ? 1 : 0
  vpc_id = var.vpc_id
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-quaternary-public-rt"
    }
  )
}

#--------------------------------------------------------------------
# Route table routes and associations for public subnets
#--------------------------------------------------------------------
resource "aws_route" "public_route_primary" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = var.public_routes.destination_cidr_block
  gateway_id             = var.public_routes.public_gateway_id
}

resource "aws_route" "public_route_secondary" {
  route_table_id         = aws_route_table.public_secondary.id
  destination_cidr_block = var.public_routes.destination_cidr_block
  gateway_id             = var.public_routes.public_gateway_id
}

resource "aws_route" "public_route_tertiary" {
  count                  = var.public_routes.has_tertiary_subnet == true ? 1 : 0
  route_table_id         = aws_route_table.public_tertiary[0].id
  destination_cidr_block = var.public_routes.destination_cidr_block
  gateway_id             = var.public_routes.public_gateway_id
}

resource "aws_route" "public_route_quaternary" {
  count                  = var.public_routes.has_quaternary_subnet == true ? 1 : 0
  route_table_id         = aws_route_table.public_quaternary[0].id
  destination_cidr_block = var.public_routes.destination_cidr_block
  gateway_id             = var.public_routes.public_gateway_id
}
resource "aws_route_table_association" "primary_public_subnet_association" {
  subnet_id      = var.public_routes.primary_subnet_id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "secondary_public_subnet_association" {
  subnet_id      = var.public_routes.secondary_subnet_id
  route_table_id = aws_route_table.public_secondary.id
}

resource "aws_route_table_association" "tertiary_public_subnet_association" {
  count          = var.public_routes.has_tertiary_subnet == true ? 1 : 0
  subnet_id      = var.public_routes.tertiary_subnet_id
  route_table_id = aws_route_table.public_tertiary.id
}

resource "aws_route_table_association" "quaternary_public_subnet_association" {
  count          = var.public_routes.has_quaternary_subnet == true ? 1 : 0
  subnet_id      = var.public_routes.quaternary_subnet_id
  route_table_id = aws_route_table.public_quaternary.id
}

