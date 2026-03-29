output "lambda_permission_statement_id" {
  description = "The statement ID of the Lambda permission."
  value       = aws_lambda_permission.this.statement_id
}

output "lambda_permission_action" {
  description = "The action granted by the Lambda permission."
  value       = aws_lambda_permission.this.action
}

output "lambda_permission_principal" {
  description = "The principal allowed by the Lambda permission."
  value       = aws_lambda_permission.this.principal
}