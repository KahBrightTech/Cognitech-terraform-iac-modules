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
  name        = "${var.common.account_name}-${var.common.region_prefix}-${var.iam_policy.name}-policy"
  description = var.iam_policy.description
  path        = var.iam_policy.path
  policy = var.iam_policy.custom_policy ? jsonencode(jsondecode(replace(
    replace(
      replace(
        replace(
          replace(
            file(var.iam_policy.policy),
            "[[account_number]]", data.aws_caller_identity.current.account_id,
          ),
          "[[account_name_abr]]", var.common.account_name_abr
        ),
        "[[region]]", data.aws_region.current.name
      ),
      "[[admin_role]]", local.admin_role_arn
    ),
    "[[network_role]]", local.network_role_arn
  ))) : jsonencode(jsondecode(file(var.iam_policy.policy)))

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.iam_policy.name}-policy"
  })
}




