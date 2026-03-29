# Output for Lambda permission statement ID
output "lambda_permission_statement_id" {
  description = "The statement ID of the Lambda permission."
  value       = aws_lambda_permission.this.statement_id
  condition   = can(aws_lambda_permission.this.statement_id)
}

# Output for Lambda permission action
output "lambda_permission_action" {
  description = "The action granted by the Lambda permission."
  value       = aws_lambda_permission.this.action
  condition   = can(aws_lambda_permission.this.action)
}

# Output for Lambda permission principal
output "lambda_permission_principal" {
  description = "The principal allowed by the Lambda permission."
  value       = aws_lambda_permission.this.principal
  condition   = can(aws_lambda_permission.this.principal)
}



