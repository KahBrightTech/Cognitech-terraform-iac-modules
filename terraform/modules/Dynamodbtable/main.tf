#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_region" "current" {}

#-------------------------------------------------------------------------
# DynamoDB Table for Terraform State Locking
#-------------------------------------------------------------------------
resource "aws_dynamodb_table" "terraform_locks" {
  name     = var.state_lock.name     # Choose a descriptive name for your table
  hash_key = var.state_lock.hash_key # The partition key must be "LockID"
  attribute {
    name = "LockID"
    type = "S" # String type for the partition key
  }
  # You can adjust the billing mode and capacity based on your needs
  billing_mode = "PAY_PER_REQUEST"
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.state_lock.name}"
  })
}
