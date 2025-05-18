#--------------------------------------------------------------------
# Primary public subnet
#--------------------------------------------------------------------
resource "aws_subnet" "primary" {
  for_each                = var.public_subnets != null && length(var.public_subnets) > 0 ? { for subnet in var.public_subnets : subnet.name => subnet } : {}
  vpc_id                  = var.vpc_id
  availability_zone       = each.value.primary_availabilty_zone
  availability_zone_id    = each.value.primary_availabilty_zone_id
  cidr_block              = each.value.primary_cidr_block
  map_public_ip_on_launch = true # This is required for public subnets
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${each.value.name}-primary"
    }
  )
}

#--------------------------------------------------------------------
# Secondary public subnet
#--------------------------------------------------------------------
resource "aws_subnet" "secondary" {
  for_each                = var.public_subnets != null && length(var.public_subnets) > 0 ? { for subnet in var.public_subnets : subnet.name => subnet } : {}
  vpc_id                  = var.vpc_id
  availability_zone       = each.value.secondary_availabilty_zone
  availability_zone_id    = each.value.secondary_availabilty_zone_id
  cidr_block              = each.value.secondary_cidr_block
  map_public_ip_on_launch = true # This is required for public subnets
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${each.value.name}-secondary"
    }
  )
}

#--------------------------------------------------------------------
# Tertiary public subnet
#--------------------------------------------------------------------
resource "aws_subnet" "tertiary" {
  for_each                = var.public_subnets != null && length(var.public_subnets) > 0 ? { for subnet in var.public_subnets : subnet.name => subnet if try(subnet.tertiary_cidr_block, null) != null } : {}
  vpc_id                  = var.vpc_id
  availability_zone       = each.value.tertiary_availabilty_zone
  availability_zone_id    = each.value.tertiary_availabilty_zone_id
  cidr_block              = each.value.tertiary_cidr_block
  map_public_ip_on_launch = true # This is required for public subnets
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${each.value.name}-tertiary"
    }
  )
}

#--------------------------------------------------------------------
# Quaternary private subnet
#--------------------------------------------------------------------
resource "aws_subnet" "quaternary" {
  for_each             = var.public_subnets != null && length(var.public_subnets) > 0 ? { for subnet in var.public_subnets : subnet.name => subnet if try(subnet.tertiary_cidr_block, null) != null } : {}
  vpc_id               = var.vpc_id
  availability_zone    = each.value.quaternary_availabilty_zone
  availability_zone_id = each.value.quaternary_availabilty_zone_id
  cidr_block           = each.value.quaternary_cidr_block
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.public_subnets.name}-quaternary"
    }
  )
}



