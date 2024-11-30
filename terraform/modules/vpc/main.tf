#--------------------------------------------------------------------
# VPC - Creates a VPC  to the target account
#--------------------------------------------------------------------
######################Creating the vpc#######################################################
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_subnet.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.vpc.name}-vpc"
    }
  )

}