#--------------------------------------------------------------------
# Resource outputs 
#--------------------------------------------------------------------
output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function"
  value       = aws_lambda_function.lambda_function.arn
}

output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.lambda_function.function_name
}
