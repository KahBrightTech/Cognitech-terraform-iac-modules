
#--------------------------------------------------------------------
# EIP - Creates an elastic Ip
# #--------------------------------------------------------------------
# resource "aws_eip" "eip" {
#   for_each = { for idx, name in var.eip.name : idx => name }
#   domain   = "vpc"
#   tags = merge(var.common.tags,
#     {
#       "Name" = "${var.common.account_name}-${var.common.region_prefix}-${each.value}-${each.key + 1}"
#     }
#   )
# }

resource "aws_eip" "eip" {
  for_each = var.primary_subnets
  domain   = "vpc"
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-eip-${each.key}"
    }
  )
}



