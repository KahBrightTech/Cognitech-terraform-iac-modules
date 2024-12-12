#--------------------------------------------------------------------
# EIP - Creates an Natgateway
#--------------------------------------------------------------------
# resource "aws_nat_gateway" "ngw" {
#   for_each      = var.ngw.name
#   allocation_id = var.ngw.allocation_id
#   subnet_id     = var.ngw.subnet_id
#   tags = merge(var.common.tags,
#     {
#       "Name" = "${var.common.account_name}-${var.common.region_prefix}-ngw-${var.ngw.name}-${each.key + 1}"
#     }
#   )
# }

resource "aws_nat_gateway" "ngw" {
  for_each = { for idx, ngw in var.ngw : ngw.name => ngw }

  allocation_id = each.value.allocation_id
  subnet_id     = each.value.subnet_id
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${each.value.name}-${each.key + 1}"
  })
}

# resource "aws_nat_gateway" "ngw" {
#   for_each      = { for idx, ngw in var.ngw : idx => ngw }
#   allocation_id = each.value.allocation_id
#   subnet_id     = each.value.subnet_id
#   tags = merge(var.common.tags, {
#     "Name" = "${var.common.account_name}-${var.common.region_prefix}-ngw-${each.key + 1}"
#   })
# }


