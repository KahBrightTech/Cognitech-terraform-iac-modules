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

# Get stable role ARNs using sort() to ensure consistent ordering
locals {
  admin_role_arn   = length(data.aws_iam_roles.admin_role.arns) > 0 ? sort(data.aws_iam_roles.admin_role.arns)[0] : ""
  network_role_arn = length(data.aws_iam_roles.network_role.arns) > 0 ? sort(data.aws_iam_roles.network_role.arns)[0] : ""
}

#--------------------------------------------------------------------
# IAM Policy - Creates IAM policy for the specified IAM role
#--------------------------------------------------------------------

resource "aws_iam_policy" "policy" {
  count       = var.ec2_profiles.create_custom_policy ? 1 : 0
  name        = "${var.common.account_name}-${var.common.region_prefix}-${var.ec2_profiles.policy.name}-policy"
  description = var.ec2_profiles.policy.description
  path        = var.ec2_profiles.policy.path
  policy = var.ec2_profiles.policy.custom_policy ? jsonencode(jsondecode(replace(
    replace(
      replace(
        replace(
          replace(
            file(var.ec2_profiles.policy.policy),
            "[[account_number]]", data.aws_caller_identity.current.account_id,
          ),
          "[[account_name_abr]]", var.common.account_name_abr
        ),
        "[[region]]", data.aws_region.current.name
      ),
      "[[admin_role]]", local.admin_role_arn
    ),
    "[[network_role]]", local.network_role_arn
  ))) : jsonencode(jsondecode(file(var.ec2_profiles.policy.policy)))

  tags = merge(var.common.tags, {
    "Name" = var.ec2_profiles.create_custom_policy ? "${var.common.account_name}-${var.common.region_prefix}-${var.ec2_profiles.policy.name}-policy" : ""
  })
}

#--------------------------------------------------------------------
# IAM Role - Creates IAM role with the specified policy
#--------------------------------------------------------------------
resource "aws_iam_role" "ec2_profiles" {
  name        = "${var.common.account_name}-${var.common.region_prefix}-${var.ec2_profiles.name}-profile"
  description = var.ec2_profiles.description
  path        = var.ec2_profiles.path
  assume_role_policy = var.ec2_profiles.custom_assume_role_policy ? jsonencode(jsondecode(replace(
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
    "[[admin_role]]", local.admin_role_arn
  ))) : jsonencode(jsondecode(file(var.ec2_profiles.assume_role_policy)))
  force_detach_policies = var.ec2_profiles.force_detach_policies
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

#--------------------------------------------------------------------
#Attach IAM Policy to Role
#--------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "policy_attachment" {
  count      = var.ec2_profiles.create_custom_policy ? 1 : 0
  role       = aws_iam_role.ec2_profiles.name
  policy_arn = aws_iam_policy.policy.arn
}

#--------------------------------------------------------------------
# Attach managed policies to Role (if provided)
#--------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "managed_policy_attachment" {
  for_each   = var.ec2_profiles.managed_policy_arns != null ? toset(var.ec2_profiles.managed_policy_arns) : []
  role       = aws_iam_role.ec2_profiles.name
  policy_arn = each.value
}


