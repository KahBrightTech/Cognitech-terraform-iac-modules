#--------------------------------------------------------------------
# Data for access keys from external source  
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "external" "create_access_key" {
  program = ["python", "${path.module}/python/iam_user_access_key.py"]

  query = {
    username = aws_iam_user.iam_user.name
  }

  depends_on = [aws_iam_user.iam_user]
}
#--------------------------------------------------------------------
# IAM User - Creates an IAM user with specified permissions
#--------------------------------------------------------------------
resource "aws_iam_user" "iam_user" {
  name                 = "${var.common.account_name}-${var.common.region_prefix}-${var.iam_user.name}"
  path                 = var.iam_user.path
  permissions_boundary = var.iam_user.permissions_boundary
  force_destroy        = var.iam_user.force_destroy
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.iam_user.name}"
    }
  )

}

#--------------------------------------------------------------------
# AWS Secrets Manager Secret for IAM User Access Keys
#--------------------------------------------------------------------
resource "aws_secretsmanager_secret" "iam_user_credentials" {
  count                   = var.iam_user.create_access_key ? 1 : 0
  name                    = "${var.common.account_name}-${var.common.region_prefix}-${var.iam_user.name}-credentials"
  description             = "Access credentials for IAM user ${var.iam_user.name}"
  recovery_window_in_days = var.iam_user.secrets_manager.recovery_window_in_days
  policy                  = var.iam_user.secrets_manager.policy

  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.iam_user.name}-credentials"
    }
  )
}

resource "aws_secretsmanager_secret_version" "iam_user_credentials" {
  count     = var.iam_user.create_access_key ? 1 : 0
  secret_id = aws_secretsmanager_secret.iam_user_credentials[0].id
  secret_string = jsonencode({
    access_key_id     = data.external.create_access_key.result["access_key_id"]
    secret_access_key = data.external.create_access_key.result["exists"] == "false" ? data.external.create_access_key.result["secret_access_key"] : "*** EXISTING KEY - SECRET NOT AVAILABLE ***"
    username          = aws_iam_user.iam_user.name
    created_date      = timestamp()
  })

  depends_on = [data.external.create_access_key]
}

#--------------------------------------------------------------------
# IAM Group 
#--------------------------------------------------------------------
resource "aws_iam_group" "iam_groups" {
  for_each = toset(var.iam_user.groups)
  name     = each.key
}

#--------------------------------------------------------------------
# IAM Group membership
#--------------------------------------------------------------------
resource "aws_iam_group_membership" "iam_group_membership" {
  count = var.iam_user.groups == null ? 0 : length(var.iam_user.groups)
  name  = var.iam_user.groups[count.index]
  users = [aws_iam_user.iam_user.name]
  group = aws_iam_group.iam_groups[var.iam_user.groups[count.index]].name
  depends_on = [
    aws_iam_user.iam_user
  ]
}

#--------------------------------------------------------------------
# IAM Group Policies
#--------------------------------------------------------------------
resource "aws_iam_policy" "group_policies" {
  for_each = {
    for policy in var.iam_user.group_policies : "${policy.group_name}-${policy.policy_name}" => policy
  }

  name        = "${var.common.account_name}-${var.common.region_prefix}-${each.value.policy_name}"
  description = each.value.description
  policy      = each.value.policy

  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${each.value.policy_name}"
    }
  )
}

#--------------------------------------------------------------------
# IAM Group Policy Attachments
#--------------------------------------------------------------------
resource "aws_iam_group_policy_attachment" "group_policy_attachments" {
  for_each = {
    for policy in var.iam_user.group_policies : "${policy.group_name}-${policy.policy_name}" => policy
  }

  group      = aws_iam_group.iam_groups[each.value.group_name].name
  policy_arn = aws_iam_policy.group_policies[each.key].arn

  depends_on = [
    aws_iam_group.iam_groups,
    aws_iam_policy.group_policies
  ]
}

#--------------------------------------------------------------------
# IAM User Policy 
#--------------------------------------------------------------------
resource "aws_iam_policy" "policy" {
  count       = var.iam_user.policy == null ? 0 : 1
  name        = "${var.common.account_name}-${var.common.region_prefix}-${var.iam_user.policy.name}"
  description = var.iam_user.policy.description
  policy      = var.iam_user.policy.policy

  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.iam_user.policy.name}"
    }
  )
}


#--------------------------------------------------------------------
# IAM User Policy Attachment
#--------------------------------------------------------------------
resource "aws_iam_user_policy_attachment" "attach_user_policy" {
  count      = var.iam_user.policy == null ? 0 : 1
  user       = aws_iam_user.iam_user.name
  policy_arn = aws_iam_policy.policy[0].arn

}
