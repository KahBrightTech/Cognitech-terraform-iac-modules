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
# Key Pair Resource
#--------------------------------------------------------------------
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_pair.name
  public_key = tls_private_key.key.public_key_openssh
}

resource "aws_secretsmanager_secret" "private_key_secret" {
  name                           = var.key_pair.secret_name
  description                    = var.key_pair.secret_description
  recovery_window_in_days        = 7
  force_overwrite_replica_secret = true
  policy                         = var.key_pair.policy

  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.secrets_manager.name}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "private_key_secret_version" {
  secret_id     = aws_secretsmanager_secret.private_key_secret.id
  secret_string = tls_private_key.key.private_key_pem
}

