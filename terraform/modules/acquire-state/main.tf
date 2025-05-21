#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_region" "current" {}

data "terraform_remote_state" "states" {
  for_each = (var.tf_remote_states != null) ? { for item in var.tf_remote_states : item.name => item } : {}
  backend  = "s3"
  config = {
    bucket       = each.value.bucket_name
    key          = each.value.bucket_key
    region       = data.aws_region.current.name
    use_lockfile = each.value.lock_table_name
    encrypt      = true
  }
}
