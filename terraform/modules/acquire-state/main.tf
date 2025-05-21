#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_region" "current" {}

data "terraform_remote_state" "states" {
  for_each = (var.tf_remote_states != null) ? { for item in var.tf_remote_states : item.name => item } : {}
  backend  = "s3"
  config = {
    bucket         = var.vpc_state_bucket
    key            = var.vpc_state_key
    region         = data.aws_region.current.name
    dynamodb_table = var.vpc_state_dynamodb_table
  }
}
