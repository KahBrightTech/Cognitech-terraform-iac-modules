# #--------------------------------------------------------------------
# # Public subnets - Creates public subnets  
# #--------------------------------------------------------------------
resource "aws_subnet" "public_subnets" {
  vpc_id                  = var.vpc_id
  for_each                = { for idx, az in var.public_subnets.az : idx => { az = az, cidr = var.public_subnets.public_subnet_cidr_block[idx] } }
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = true
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.public_subnets.public_subnet_name}-${each.key + 1}"
    }
  )
}
