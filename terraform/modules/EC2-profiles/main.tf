#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_roles" "admin_role" {
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "network_role" {
  name_regex  = "AWSReservedSSO_NetworkAdministrator_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}
#--------------------------------------------------------------------
# IAM Role - Creates IAM role with the specified policy
#--------------------------------------------------------------------
resource "aws_iam_role" "ec2_profiles" {
  name        = "${var.common.account_name}-${var.common.region_prefix}-${var.ec2_profiles.name}-profile"
  description = var.ec2_profiles.description
  path        = var.ec2_profiles.path
  assume_role_policy = var.ec2_profiles.custom_assume_role_policy ? replace(
    replace(
      replace(
        replace(
          file(var.ec2_profiles.assume_role_policy),
          "[[account_number]]", data.aws_caller_identity.current.account_id
        ),
        "[[account_name_abr]]", var.common.account_name_abr
      ),
      "[[region]]", data.aws_region.current.name
    ),
    "[[admin_role]]", tolist(data.aws_iam_roles.admin_role.arns)[0]
  ) : file(var.ec2_profiles.assume_role_policy)
  force_detach_policies = var.ec2_profiles.force_detach_policies
  managed_policy_arns   = var.ec2_profiles.managed_policy_arns
  max_session_duration  = var.ec2_profiles.max_session_duration
  permissions_boundary  = var.ec2_profiles.permissions_boundary
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.ec2_profiles.policy.name}-profile"
  })
}

#--------------------------------------------------------------------
# IAM Profile - Creates IAM profile for the specified IAM role
resource "aws_iam_instance_profile" "ec2_profiles" {
  name = "${var.common.account_name}-${var.common.region_prefix}-${var.ec2_profiles.name}-ec2-profile"
  role = aws_iam_role.ec2_profiles.name

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.ec2_profiles.name}-ec2-profile"
  })
}



