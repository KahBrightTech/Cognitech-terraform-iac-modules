#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
# Get stable role ARNs using sort() to ensure consistent ordering
#--------------------------------------------------------------------
# ALB - Creates an Application Load Balancer
#--------------------------------------------------------------------

module "alb" {
  source        = "../Load-Balancers"
  common        = var.common
  load_balancer = var.load_balancer
}

module "target_group" {
  source       = "../Target-Groups"
  common       = var.common
  target_group = var.target_group
}
