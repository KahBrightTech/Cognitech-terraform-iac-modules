#--------------------------------------------------------------------
# IAM Policy outputs
#--------------------------------------------------------------------
output "iam_policy_id" {
  description = "The ID of the IAM policy created for the role"
  value       = aws_iam_policy.policy.id
}
output "iam_policy_arn" {
  description = "The ARN of the IAM policy created for the role"
  value       = aws_iam_policy.policy.arn
}

output "aws_iam_policy_name" {
  description = "The name of the IAM policy created for the role"
  value       = aws_iam_policy.policy.name
}


