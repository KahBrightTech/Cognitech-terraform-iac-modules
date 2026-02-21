
output "instance_profile_name" {
  description = "The name of the EC2 instance profile."
  value       = aws_iam_instance_profile.ec2_profiles.name
}
#--------------------------------------------------------------------
# Outputs for EC2 Profiles Module
#--------------------------------------------------------------------
output "iam_profiles" {
  description = "The EC2 IAM instance profiles map"
  value       = var.ec2_profiles != null ? aws_iam_instance_profile.ec2_profiles : null
}
#--------------------------------------------------------------------
# IAM Policy outputs
#--------------------------------------------------------------------
output "iam_policy_id" {
  description = "The ID of the IAM policy created for the role"
  value       = length(aws_iam_policy.policy) > 0 ? aws_iam_policy.policy[0].id : null
}
output "iam_policy_arn" {
  description = "The ARN of the IAM policy created for the role"
  value       = length(aws_iam_policy.policy) > 0 ? aws_iam_policy.policy[0].arn : null
}

output "aws_iam_policy_name" {
  description = "The name of the IAM policy created for the role"
  value       = length(aws_iam_policy.policy) > 0 ? aws_iam_policy.policy[0].name : null
}

#--------------------------------------------------------------------
# IAM Role outputs
#--------------------------------------------------------------------
output "iam_role_id" {
  description = "The ID of the IAM role created"
  value       = aws_iam_role.ec2_profiles.id
}

output "iam_role_arn" {
  description = "The ARN of the IAM role created"
  value       = aws_iam_role.ec2_profiles.arn
}

output "aws_iam_role_name" {
  description = "The name of the IAM role created"
  value       = aws_iam_role.ec2_profiles.name
}

