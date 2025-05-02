
output "iam_uer_arn" {
  description = "The ARN of the IAM User"
  value       = aws_iam_user.iam_user.arn
}

output "iam_user_name" {
  description = "The name of the IAM User"
  value       = aws_iam_user.iam_user.name
}
