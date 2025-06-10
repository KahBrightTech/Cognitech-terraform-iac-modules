#--------------------------------------------------------------------
# Outputs for EC2 Profiles Module
#--------------------------------------------------------------------
output "ec2_iam_instance_profile_id" {
  description = "The EC2 IAM instance profiles map"
  value       = var.ec2_profiles != null ? aws_iam_instance_profile.ec2_profiles : null
}

