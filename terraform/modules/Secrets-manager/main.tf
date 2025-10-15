resource "aws_secretsmanager_secret" "secret" {
  count                          = 1
  name                           = "${var.common.account_name}-${var.common.region_prefix}-${var.secrets_manager.name}"
  description                    = var.secrets_manager.description
  recovery_window_in_days        = var.secrets_manager.recovery_window_in_days
  force_overwrite_replica_secret = true
  policy                         = var.secrets_manager.policy

  # tags = merge(var.common.tags,
  #   {
  #     Name = "${var.common.account_name}-${var.common.region_prefix}-${var.secrets_manager.name}"
  #   }
  # )
}

resource "aws_secretsmanager_secret_version" "secret" {
  count = 1
  # count         = length(aws_secretsmanager_secret.secret) > 0 ? 1 : 0
  secret_id     = aws_secretsmanager_secret.secret[0].id
  secret_string = jsonencode(var.secrets_manager.value)
}



