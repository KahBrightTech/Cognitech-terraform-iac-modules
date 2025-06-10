#--------------------------------------------------------------------
# Outputs for EC2 Profiles Module
#--------------------------------------------------------------------
output "ec2_iam_instance_profile_id" {
  description = "The ID of the EC2 IAM instance profile created"
  value = var.ec2_profiles != null ? {
    for key, item in aws_iam_instance_profile.ec2_profiles :
    key => {
      id   = item.id
      arn  = item.arn
      name = item.name
    }
  } : null

}
