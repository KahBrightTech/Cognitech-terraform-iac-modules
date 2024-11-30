#--------------------------------------------------------------------
# VPC - Creates a VPC  to the target account
#--------------------------------------------------------------------
module "vpc" {
  source = "../../../modules/vpc"
  for_each = var.vpc != null ? { for item in var.vpc : item.key => item } : {} 
    
  common = var.common
  vpc = each.value 
}