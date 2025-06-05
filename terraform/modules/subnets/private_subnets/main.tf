#--------------------------------------------------------------------
# Primary private subnet
#--------------------------------------------------------------------
resource "aws_subnet" "primary" {
  vpc_id            = var.vpc_id
  availability_zone = var.private_subnets.primary_availability_zone
  cidr_block        = var.private_subnets.primary_cidr_block
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.private_subnets.name}-${var.private_subnets.subnet_type}-primary"
    }
  )
}

#--------------------------------------------------------------------
# Secondary private subnet
#--------------------------------------------------------------------
resource "aws_subnet" "secondary" {
  vpc_id            = var.vpc_id
  availability_zone = var.private_subnets.secondary_availability_zone
  cidr_block        = var.private_subnets.secondary_cidr_block
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.private_subnets.name}-${var.private_subnets.subnet_type}-secondary"
    }
  )
}

#--------------------------------------------------------------------
# Tertiary private subnet
#--------------------------------------------------------------------
resource "aws_subnet" "tertiary" {
  count             = var.private_subnets.tertiary_cidr_block != null ? 1 : 0
  vpc_id            = var.vpc_id
  availability_zone = var.private_subnets.tertiary_availability_zone
  cidr_block        = var.private_subnets.tertiary_cidr_block
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.private_subnets.name}-${var.private_subnets.subnet_type}-tertiary"
    }
  )
}

#--------------------------------------------------------------------
# Quaternary private subnet
#--------------------------------------------------------------------
resource "aws_subnet" "quaternary" {
  count             = var.private_subnets.quaternary_cidr_block != null ? 1 : 0
  vpc_id            = var.vpc_id
  availability_zone = var.private_subnets.quaternary_availability_zone
  cidr_block        = var.private_subnets.quaternary_cidr_block
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.private_subnets.name}-${var.private_subnets.subnet_type}-quaternary"
    }
  )
}

