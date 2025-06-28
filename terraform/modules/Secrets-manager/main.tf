#--------------------------------------------------------------------
# Data for access keys from external source  
#--------------------------------------------------------------------
data "secretsmanager_field" "fsx_secrets_login" {
  count = var.secrets_manager.record_folder_uid != null && var.secrets_manager.record_folder_uid != "" ? 1 : 0
  path  = "${var.secrets_manager.record_folder_uid}/field/login"
}

data "secretsmanager_field" "fsx_secrets_password" {
  count = var.secrets_manager.record_folder_uid != null && var.secrets_manager.record_folder_uid != "" ? 1 : 0
  path  = "${var.secrets_manager.record_folder_uid}/field/password"
}

locals {
  use_external_secrets = trim(coalesce(var.secrets_manager.record_folder_uid, ""), " \t\n\r") != ""

  secret_value = local.use_external_secrets ? jsonencode({
    username = data.secretsmanager_field.fsx_secrets_login[0].value
    password = data.secretsmanager_field.fsx_secrets_password[0].value
  }) : jsonencode(var.secrets_manager.value)
}

resource "aws_secretsmanager_secret" "secret" {
  count                          = 1
  name                           = "${var.common.account_name}-${var.common.region_prefix}-${var.secrets_manager.name}"
  description                    = var.secrets_manager.description
  recovery_window_in_days        = var.secrets_manager.recovery_window_in_days
  force_overwrite_replica_secret = true
  policy                         = var.secrets_manager.policy

  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.secrets_manager.name}"
    }
  )

}

resource "aws_secretsmanager_secret_version" "secret" {
  count = 1
  # count         = length(aws_secretsmanager_secret.secret) > 0 ? 1 : 0
  secret_id     = aws_secretsmanager_secret.secret[0].id
  secret_string = local.secret_value
}



