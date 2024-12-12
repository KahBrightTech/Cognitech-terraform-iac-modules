
#--------------------------------------------------------------------
# EIP - Creates an elastic Ip
#--------------------------------------------------------------------
resource "aws_eip" "eip" {
  for_each = var.eip.name
  domain   = "vpc"
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eip.name}-${each.key + 1}"
    }
  )
}


