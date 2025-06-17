#--------------------------------------------------------------------
# Outputs for the DynamoDB table module 
#--------------------------------------------------------------------
output "dynamodb_table_name" {
  description = "The name of the DynamoDB table used for Terraform state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}
