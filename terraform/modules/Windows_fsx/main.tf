#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
# Get stable role ARNs using sort() to ensure consistent ordering
#--------------------------------------------------------------------
# Creates Windows FSx File System
#--------------------------------------------------------------------
resource "aws_fsx_windows_file_system" "main" {
  # Required parameters
  storage_capacity    = var.windows_fsx.storage_capacity
  throughput_capacity = var.windows_fsx.throughput_capacity
  subnet_ids          = var.windows_fsx.subnet_ids

  # Optional parameters with defaults
  storage_type        = var.windows_fsx.storage_type
  deployment_type     = var.windows_fsx.deployment_type
  preferred_subnet_id = var.windows_fsx.preferred_subnet_id
  security_group_ids  = var.windows_fsx.security_group_ids
  kms_key_id          = var.windows_fsx.kms_key_id

  # Active Directory configuration
  active_directory_id = var.windows_fsx.active_directory_id

  # Self-managed Active Directory configuration
  dynamic "self_managed_active_directory" {
    for_each = var.windows_fsx.self_managed_active_directory != null ? [var.windows_fsx.self_managed_active_directory] : []
    content {
      dns_ips                                = self_managed_active_directory.value.dns_ips
      domain_name                            = self_managed_active_directory.value.domain_name
      password                               = self_managed_active_directory.value.password
      username                               = self_managed_active_directory.value.username
      file_system_administrators_group       = self_managed_active_directory.value.file_system_administrators_group
      organizational_unit_distinguished_name = self_managed_active_directory.value.organizational_unit_distinguished_name
    }
  }

  # Backup configuration
  automatic_backup_retention_days   = var.windows_fsx.automatic_backup_retention_days
  daily_automatic_backup_start_time = var.windows_fsx.daily_automatic_backup_start_time
  weekly_maintenance_start_time     = var.windows_fsx.weekly_maintenance_start_time
  copy_tags_to_backups              = var.windows_fsx.copy_tags_to_backups
  skip_final_backup                 = var.windows_fsx.skip_final_backup

  # Audit logs configuration
  dynamic "audit_log_configuration" {
    for_each = var.windows_fsx.audit_log_configuration != null ? [var.windows_fsx.audit_log_configuration] : []
    content {
      file_access_audit_log_level       = audit_log_configuration.value.file_access_audit_log_level
      file_share_access_audit_log_level = audit_log_configuration.value.file_share_access_audit_log_level
      audit_log_destination             = audit_log_configuration.value.audit_log_destination
    }
  }

  # Disk IOPS configuration for SSD storage type
  dynamic "disk_iops_configuration" {
    for_each = var.windows_fsx.storage_type == "SSD" && var.windows_fsx.disk_iops_configuration != null ? [var.windows_fsx.disk_iops_configuration] : []
    content {
      mode = disk_iops_configuration.value.mode
      iops = disk_iops_configuration.value.iops
    }
  }

  tags = merge(
    var.common.tags,
    {
      Name = "${var.common.account_name_abr}-${var.common.region_prefix}-${var.windows_fsx.name}-fsx"
    }
  )

  dynamic "lifecycle" {
    for_each = var.windows_fsx.prevent_destroy ? [1] : []
    content {
      prevent_destroy = true
    }
  }
}
