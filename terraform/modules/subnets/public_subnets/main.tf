#--------------------------------------------------------------------
# Primary public subnet
#--------------------------------------------------------------------
resource "aws_subnet" "primary" {
  vpc_id                  = var.vpc_id
  availability_zone       = var.public_subnets.primary_availability_zone
  availability_zone_id    = var.public_subnets.primary_availability_zone_id
  cidr_block              = var.public_subnets.primary_cidr_block
  map_public_ip_on_launch = true # This is required for public subnets
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.public_subnets.name}-${var.public_subnets.subnet_type}-primary"
    }
  )
}

#--------------------------------------------------------------------
# Secondary public subnet
#--------------------------------------------------------------------
resource "aws_subnet" "secondary" {
  vpc_id                  = var.vpc_id
  availability_zone       = var.public_subnets.secondary_availability_zone
  availability_zone_id    = var.public_subnets.secondary_availability_zone_id
  cidr_block              = var.public_subnets.secondary_cidr_block
  map_public_ip_on_launch = true # This is required for public subnets
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.public_subnets.name}-${var.public_subnets.subnet_type}-secondary"
    }
  )
}

#--------------------------------------------------------------------
# Tertiary public subnet
#--------------------------------------------------------------------
resource "aws_subnet" "tertiary" {
  count                   = var.public_subnets.tertiary_cidr_block != null ? 1 : 0
  vpc_id                  = var.vpc_id
  availability_zone       = var.public_subnets.tertiary_availability_zone
  availability_zone_id    = var.public_subnets.tertiary_availability_zone_id
  cidr_block              = var.public_subnets.tertiary_cidr_block
  map_public_ip_on_launch = true # This is required for public subnets
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.public_subnets.name}-${var.public_subnets.subnet_type}-tertiary"
    }
  )
}

#--------------------------------------------------------------------
# Quaternary private subnet
#--------------------------------------------------------------------
resource "aws_subnet" "quaternary" {
  count                = var.public_subnets.quaternary_cidr_block != null ? 1 : 0
  vpc_id               = var.vpc_id
  availability_zone    = var.public_subnets.quaternary_availability_zone
  availability_zone_id = var.public_subnets.quaternary_availability_zone_id
  cidr_block           = var.public_subnets.quaternary_cidr_block
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.public_subnets.name}-${var.public_subnets.subnet_type}-quaternary"
    }
  )
}



