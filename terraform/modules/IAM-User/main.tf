#--------------------------------------------------------------------
# Data for access keys from external source  
#--------------------------------------------------------------------
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
# IAM Keeper Secret 
#--------------------------------------------------------------------
resource "secretsmanager_login" "iam_user_access_key" {
  depends_on = [data.external.create_access_key]
  folder_uid = var.iam_user.keeper_folder_uid
  title      = "${var.common.account_name}-${var.common.region_prefix}-${var.iam_user.name}"
  login {
    required       = true
    privacy_screen = true
    value          = data.external.create_access_key.result["AccessKeyId"]
  }
  password {
    required       = true
    privacy_screen = true
    value          = data.external.create_access_key.result["Exist"] == "false" ? data.external.create_access_key.result["SecretAccessKey"] : null
  }

}

#--------------------------------------------------------------------
# IAM Group membership
#--------------------------------------------------------------------
resource "aws_iam_group_membership" "iam_group_membership" {
  count = var.iam_user.groups == null ? 0 : length(var.iam_user.groups)
  name  = var.iam_user.groups[count.index]
  users = [aws_iam_user.iam_user.name]
  group = var.iam_user.groups[count.index]

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
