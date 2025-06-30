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
  name        = "${var.common.account_name}-${var.common.region_prefix}-${var.iam_role.policy.name}-policy"
  description = var.iam_role.policy.description
  path        = var.iam_role.policy.path
  policy = var.iam_role.policy.custom_policy ? jsonencode(jsondecode(replace(
    replace(
      replace(
        replace(
          replace(
            file(var.iam_role.policy.policy),
            "[[account_number]]", data.aws_caller_identity.current.account_id,
          ),
          "[[account_name_abr]]", var.common.account_name_abr
        ),
        "[[region]]", data.aws_region.current.name
      ),
      "[[admin_role]]", local.admin_role_arn
    ),
    "[[network_role]]", local.network_role_arn
  ))) : jsonencode(jsondecode(file(var.iam_role.policy.policy)))

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.iam_role.policy.name}-policy"
  })
}

#--------------------------------------------------------------------
# IAM Role - Creates IAM role with the specified policy
#--------------------------------------------------------------------
resource "aws_iam_role" "role" {
  name        = "${var.common.account_name}-${var.common.region_prefix}-${var.iam_role.name}-role"
  description = var.iam_role.description
  path        = var.iam_role.path
  assume_role_policy = var.iam_role.custom_assume_role_policy ? jsonencode(jsondecode(replace(
    replace(
      replace(
        replace(
          file(var.iam_role.assume_role_policy),
          "[[account_number]]", data.aws_caller_identity.current.account_id
        ),
        "[[account_name_abr]]", var.common.account_name_abr
      ),
      "[[region]]", data.aws_region.current.name
    ),
    "[[admin_role]]", local.admin_role_arn
  ))) : jsonencode(jsondecode(file(var.iam_role.assume_role_policy)))
  force_detach_policies = var.iam_role.force_detach_policies
  managed_policy_arns   = var.iam_role.managed_policy_arns
  max_session_duration  = var.iam_role.max_session_duration
  permissions_boundary  = var.iam_role.permissions_boundary
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.iam_role.policy.name}-role"
  })
}


#--------------------------------------------------------------------
#Attach IAM Policy to Role
#--------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}
