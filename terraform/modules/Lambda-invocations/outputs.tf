output "lambda_permission_statement_ids" {
  description = "The statement IDs of the Lambda permissions."
  value       = { for k, v in aws_lambda_permission.this : k => v.statement_id }
}

output "lambda_permission_actions" {
  description = "The actions granted by the Lambda permissions."
  value       = { for k, v in aws_lambda_permission.this : k => v.action }
}

output "lambda_permission_principals" {
  description = "The principals allowed by the Lambda permissions."
  value       = { for k, v in aws_lambda_permission.this : k => v.principal }
}