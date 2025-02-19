#--------------------------------------------------------------------
# Primary public subnet
#--------------------------------------------------------------------
resource "aws_subnet" "primary" {
  vpc_id                  = var.vpc_id
  availability_zone       = var.public_subnets.primary_availabilty_zone
  availability_zone_id    = var.public_subnets.primary_availabilty_zone_id
  cidr_block              = var.public_subnets.primary_cidr_block
  map_public_ip_on_launch = true # This is required for public subnets
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.public_subnets.name}-primary"
    }
  )
}

#--------------------------------------------------------------------
# Secondary public subnet
#--------------------------------------------------------------------
resource "aws_subnet" "secondary" {
  vpc_id                  = var.vpc_id
  availability_zone       = var.public_subnets.primary_availabilty_zone
  availability_zone_id    = var.public_subnets.primary_availabilty_zone_id
  cidr_block              = var.public_subnets.primary_cidr_block
  map_public_ip_on_launch = true # This is required for public subnets
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.public_subnets.name}-secondary"
    }
  )
}

#--------------------------------------------------------------------
# Tertiary public subnet
#--------------------------------------------------------------------
resource "aws_subnet" "secondary" {
  vpc_id                  = var.vpc_id
  availability_zone       = var.public_subnets.primary_availabilty_zone
  availability_zone_id    = var.public_subnets.primary_availabilty_zone_id
  cidr_block              = var.public_subnets.primary_cidr_block
  map_public_ip_on_launch = true # This is required for public subnets
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.public_subnets.name}-tertiary"
    }
  )
}
