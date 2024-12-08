#--------------------------------------------------------------------
# Private subnets - Creates privates subnets
#--------------------------------------------------------------------
resource "aws_subnet" "subnets" {
  vpc_id                  = var.vpc_id
  for_each                = { for idx, az in var.subnets.az : idx => { az = az, cidr = var.subnets.subnet_cidr_block[idx] } }
  availability_zone       = each.value.az
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = var.subnet.map_public_ip_on_launch
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.subnets.subnet_name}-${each.key + 1}"
    }
  )
}
# resource "aws_subnet" "private_subnets" {
#   vpc_id            = var.vpc_id
#   for_each          = { for idx, az in var.private_subnets.az : idx => { az = az, cidr = var.private_subnets.private_subnet_cidr_block[idx] } }
#   availability_zone = each.value.az
#   cidr_block        = each.value.cidr
#   tags = merge(var.common.tags,
#     {
#       "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.private_subnets.private_subnet_name}-${each.key + 1}"
#     }
#   )
# }

# #--------------------------------------------------------------------
# # Public subnets - Creates public subnets  
# #--------------------------------------------------------------------
# resource "aws_subnet" "public_subnets" {
#   vpc_id                  = var.vpc_id
#   for_each                = { for idx, az in var.public_subnets.az : idx => { az = az, cidr = var.public_subnets.public_subnet_cidr_block[idx] } }
#   availability_zone       = each.value.az
#   cidr_block              = each.value.cidr
#   map_public_ip_on_launch = true
#   tags = merge(var.common.tags,
#     {
#       "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.public_subnets.public_subnet_name}-${each.key + 1}"
#     }
#   )
# }
