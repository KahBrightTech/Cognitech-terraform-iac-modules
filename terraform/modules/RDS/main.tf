#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#--------------------------------------------------------------------
# Generate random password for RDS
#--------------------------------------------------------------------
resource "random_password" "master_password" {
  count            = var.rds_instance != null ? 1 : 0
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

#--------------------------------------------------------------------
# Create DB Subnet Group
#--------------------------------------------------------------------
resource "aws_db_subnet_group" "group" {
  count      = var.rds_instance != null ? 1 : 0
  name       = "${var.common.account_name}-${var.rds_instance.name}-subnet-group"
  subnet_ids = var.rds_instance.subnet_ids

  tags = merge(
    var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.rds_instance.name}-subnet-group"
    }
  )
}

#--------------------------------------------------------------------
# Create DB Parameter Group
#--------------------------------------------------------------------
resource "aws_db_parameter_group" "parameter_group" {
  count = var.rds_instance != null && var.rds_instance.create_parameter_group ? 1 : 0

  name        = "${var.common.account_name}-${var.common.region_prefix}-${var.rds_instance.name}-parameter-group"
  family      = var.rds_instance.parameter_group_family
  description = "Custom parameter group for ${var.rds_instance.name}"

  dynamic "parameter" {
    for_each = var.rds_instance.parameters != null ? var.rds_instance.parameters : []
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", "immediate")
    }
  }

  tags = merge(
    var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.rds_instance.name}-parameter-group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

#--------------------------------------------------------------------
# Create RDS Instance
#--------------------------------------------------------------------
resource "aws_db_instance" "instance" {
  count = var.rds_instance != null ? 1 : 0

  identifier     = "${var.common.account_name}-${var.common.region_prefix}-${var.rds_instance.name}"
  engine         = var.rds_instance.engine
  engine_version = var.rds_instance.engine_version
  instance_class = var.rds_instance.instance_class

  allocated_storage     = var.rds_instance.allocated_storage
  max_allocated_storage = var.rds_instance.max_allocated_storage
  storage_type          = var.rds_instance.storage_type
  storage_encrypted     = var.rds_instance.storage_encrypted
  kms_key_id            = var.rds_instance.kms_key_id
  iops                  = var.rds_instance.iops

  db_name  = var.rds_instance.database_name
  username = var.rds_instance.master_username
  password = random_password.master_password[0].result
  port     = var.rds_instance.port

  db_subnet_group_name   = aws_db_subnet_group.group[0].name
  vpc_security_group_ids = var.rds_instance.vpc_security_group_ids
  publicly_accessible    = var.rds_instance.publicly_accessible

  multi_az             = var.rds_instance.multi_az
  availability_zone    = var.rds_instance.availability_zone
  parameter_group_name = var.rds_instance.create_parameter_group ? aws_db_parameter_group.parameter_group[0].name : var.rds_instance.parameter_group_name
  option_group_name    = var.rds_instance.option_group_name

  backup_retention_period    = var.rds_instance.backup_retention_period
  backup_window              = var.rds_instance.backup_window
  maintenance_window         = var.rds_instance.maintenance_window
  auto_minor_version_upgrade = var.rds_instance.auto_minor_version_upgrade

  deletion_protection       = var.rds_instance.deletion_protection
  skip_final_snapshot       = var.rds_instance.skip_final_snapshot
  final_snapshot_identifier = var.rds_instance.skip_final_snapshot ? null : "${var.common.account_name}-${var.rds_instance.name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  copy_tags_to_snapshot     = var.rds_instance.copy_tags_to_snapshot

  enabled_cloudwatch_logs_exports       = var.rds_instance.enabled_cloudwatch_logs_exports
  monitoring_interval                   = var.rds_instance.monitoring_interval
  monitoring_role_arn                   = var.rds_instance.monitoring_role_arn
  performance_insights_enabled          = var.rds_instance.performance_insights_enabled
  performance_insights_kms_key_id       = var.rds_instance.performance_insights_kms_key_id
  performance_insights_retention_period = var.rds_instance.performance_insights_retention_period

  apply_immediately = var.rds_instance.apply_immediately

  tags = merge(
    var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.rds_instance.name}"
    }
  )

  lifecycle {
    ignore_changes = [
      password,
      final_snapshot_identifier
    ]
  }
}

#--------------------------------------------------------------------
# Store RDS credentials and connection info in Secrets Manager
#--------------------------------------------------------------------
resource "aws_secretsmanager_secret" "rds_credentials" {
  count = var.rds_instance != null ? 1 : 0

  name        = "${var.common.account_name}/${var.rds_instance.name}/rds-credentials"
  description = "RDS credentials and connection information for ${var.rds_instance.name}"
  kms_key_id  = var.rds_instance.secrets_kms_key_id

  recovery_window_in_days = var.rds_instance.secret_recovery_window_days

  tags = merge(
    var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.rds_instance.name}-credentials"
    }
  )
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  count = var.rds_instance != null ? 1 : 0

  secret_id = aws_secretsmanager_secret.rds_credentials[0].id
  secret_string = jsonencode({
    username = aws_db_instance.instance[0].username
    password = random_password.master_password[0].result
    host     = aws_db_instance.instance[0].address
    endpoint = aws_db_instance.instance[0].endpoint
    port     = aws_db_instance.instance[0].port
  })
}

#--------------------------------------------------------------------
# Create read replica (optional)
#--------------------------------------------------------------------
resource "aws_db_instance" "read_replica" {
  count = var.rds_instance != null && var.rds_instance.create_read_replica ? 1 : 0

  identifier                 = "${var.common.account_name}-${var.rds_instance.name}-replica"
  replicate_source_db        = aws_db_instance.instance[0].identifier
  instance_class             = var.rds_instance.replica_instance_class != null ? var.rds_instance.replica_instance_class : var.rds_instance.instance_class
  auto_minor_version_upgrade = var.rds_instance.auto_minor_version_upgrade
  publicly_accessible        = var.rds_instance.publicly_accessible
  vpc_security_group_ids     = var.rds_instance.vpc_security_group_ids

  skip_final_snapshot = true

  performance_insights_enabled    = var.rds_instance.performance_insights_enabled
  performance_insights_kms_key_id = var.rds_instance.performance_insights_kms_key_id

  tags = merge(
    var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.rds_instance.name}-replica"
    }
  )
}
