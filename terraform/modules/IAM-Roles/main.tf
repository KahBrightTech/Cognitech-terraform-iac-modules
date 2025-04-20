#--------------------------------------------------------------------
# VPC - Creates a VPC  to the target account
#--------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.vpc.name}-vpc"
    }
  )

}

#--------------------------------------------------------------------
# VPC - Creates and associates internet gateway to vpc 
#--------------------------------------------------------------------
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.vpc.name}-igw"
    }
  )
}
