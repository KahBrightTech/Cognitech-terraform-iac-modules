resource "aws_secretsmanager_secret" "secret" {
  count                          = var.secrets_manager != null ? 1 : 0
  name                           = var.secrets_manager.name != null ? "${var.common.account_name}-${var.common.region_prefix}-${var.secrets_manager.name}" : null
  name_prefix                    = var.secrets_manager.name == null && var.secrets_manager.name_prefix != null ? "${var.common.account_name}-${var.common.region_prefix}-${var.secrets_manager.name_prefix}" : null
  description                    = var.secrets_manager.description
  recovery_window_in_days        = var.secrets_manager.recovery_window_in_days
  force_overwrite_replica_secret = true
  policy                         = var.secrets_manager.policy

  # tags = merge(var.common.tags,
  #   {
  #     Name = var.secrets_manager.name != null ? "${var.common.account_name}-${var.common.region_prefix}-${var.secrets_manager.name}" : "${var.common.account_name}-${var.common.region_prefix}-${var.secrets_manager.name_prefix != null ? var.secrets_manager.name_prefix : "secret"}"
  #   }
  # )
}

resource "aws_secretsmanager_secret_version" "secret" {
  count         = var.secrets_manager != null && var.secrets_manager.value != null ? 1 : 0
  secret_id     = aws_secretsmanager_secret.secret[0].id
  secret_string = jsonencode(var.secrets_manager.value)
}



