#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_region" "current" {}

#-------------------------------------------------------------------------
# DynamoDB Table for Terraform State Locking
#-------------------------------------------------------------------------
resource "aws_dynamodb_table" "terraform_locks" {
  name     = var.state_lock.table_name
  hash_key = var.state_lock.hash_key
  attribute {
    name = var.state_lock.attributes.name
    type = var.state_lock.attributes.type
  }
  # You can adjust the billing mode and capacity based on your needs
  billing_mode = var.state_lock.billing_mode
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.state_lock.table_name}"
  })
}
