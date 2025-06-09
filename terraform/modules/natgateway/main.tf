#--------------------------------------------------------------------
#EIP - Creates an elastic Ip
#--------------------------------------------------------------------
resource "aws_eip" "primary" {
  count                = var.nat_gateway.type == "public" ? 1 : 0
  network_border_group = var.common.region
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.nat_gateway.vpc_name}-${var.nat_gateway.subnet_name}-eip-${var.nat_gateway.name}-primary"
    }
  )
}

resource "aws_eip" "secondary" {
  count                = var.nat_gateway.type == "public" ? 1 : 0
  network_border_group = var.common.region
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.nat_gateway.vpc_name}-${var.nat_gateway.subnet_name}-eip-${var.nat_gateway.name}-secondary"
    }
  )
}

resource "aws_eip" "tertiary" {
  count                = var.nat_gateway.has_tertiary_subnet == true && var.nat_gateway.type == "public" ? 1 : 0
  network_border_group = var.common.region
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.nat_gateway.vpc_name}-${var.nat_gateway.subnet_name}-eip-${var.nat_gateway.name}-tertiary"
    }
  )
}

resource "aws_eip" "quaternary" {
  count                = var.nat_gateway.has_quaternary_subnet == true && var.nat_gateway.type == "public" ? 1 : 0
  network_border_group = var.common.region
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.nat_gateway.vpc_name}-${var.nat_gateway.subnet_name}-eip-${var.nat_gateway.name}-quaternary"
    }
  )
}


#--------------------------------------------------------------------
#NAT - Creates an Natgateway
#--------------------------------------------------------------------
resource "aws_nat_gateway" "primary" {
  count         = var.bypass == false ? 1 : 0
  allocation_id = var.nat_gateway.type == "public" ? aws_eip.primary[0].id : null
  subnet_id     = var.nat_gateway.subnet_id_primary
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.nat_gateway.vpc_name}-${var.nat_gateway.subnet_name}-ngw-${var.nat_gateway.name}-primary"
    }
  )
}

resource "aws_nat_gateway" "secondary" {
  count         = var.bypass == false ? 1 : 0
  allocation_id = var.nat_gateway.type == "public" ? aws_eip.secondary[0].id : null
  subnet_id     = var.nat_gateway.subnet_id_secondary
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.nat_gateway.vpc_name}-${var.nat_gateway.subnet_name}-ngw-${var.nat_gateway.name}-secondary"
    }
  )
}

resource "aws_nat_gateway" "tertiary" {
  count         = var.nat_gateway.has_tertiary_subnet == true && var.bypass == false ? 1 : 0
  allocation_id = var.nat_gateway.type == "public" ? aws_eip.tertiary[0].id : null
  subnet_id     = var.nat_gateway.subnet_id_tertiary
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.nat_gateway.vpc_name}-${var.nat_gateway.subnet_name}-ngw-${var.nat_gateway.name}-tertiary"
    }
  )
}

resource "aws_nat_gateway" "quaternary" {
  count         = var.nat_gateway.has_quaternary_subnet == true && var.bypass == false ? 1 : 0
  allocation_id = var.nat_gateway.type == "public" ? aws_eip.quaternary[0].id : null
  subnet_id     = var.nat_gateway.subnet_id_quaternary
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.nat_gateway.vpc_name}-${var.nat_gateway.subnet_name}-ngw-${var.nat_gateway.name}-quaternary"
    }
  )
}
