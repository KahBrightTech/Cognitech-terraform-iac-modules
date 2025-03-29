#--------------------------------------------------------------------
# Security Group - Create a security group for the VPC
#--------------------------------------------------------------------
resource "aws_security_group" "main" {
  count       = var.bypass == false ? 1 : 0
  name        = var.security_group.name
  description = var.security_group.description
  vpc_id      = var.security_group.vpc_id
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.vpc.name}-vpc"
    }
  )

}


