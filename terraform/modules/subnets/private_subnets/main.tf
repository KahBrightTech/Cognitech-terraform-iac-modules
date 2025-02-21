#--------------------------------------------------------------------
# Primary private subnet
#--------------------------------------------------------------------
resource "aws_subnet" "primary" {
  vpc_id               = var.vpc_id
  availability_zone    = var.private_subnets.primary_availabilty_zone
  availability_zone_id = var.private_subnets.primary_availabilty_zone_id
  cidr_block           = var.private_subnets.primary_cidr_block
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.private_subnets.name}-primary"
    }
  )
}

#--------------------------------------------------------------------
# Secondary private subnet
#--------------------------------------------------------------------
resource "aws_subnet" "secondary" {
  vpc_id               = var.vpc_id
  availability_zone    = var.private_subnets.secondary_availabilty_zone
  availability_zone_id = var.private_subnets.secondary_availabilty_zone_id
  cidr_block           = var.private_subnets.secondary_cidr_block
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.private_subnets.name}-secondary"
    }
  )
}

#--------------------------------------------------------------------
# Tertiary private subnet
#--------------------------------------------------------------------
resource "aws_subnet" "tertiary" {
  vpc_id               = var.vpc_id
  availability_zone    = var.private_subnets.tertiary_availabilty_zone
  availability_zone_id = var.private_subnets.tertiary_availabilty_zone_id
  cidr_block           = var.private_subnets.tertiary_cidr_block
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.private_subnets.name}-tertiary"
    }
  )
}

