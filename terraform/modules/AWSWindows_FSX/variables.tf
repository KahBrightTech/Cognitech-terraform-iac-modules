variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global           = bool
    tags             = map(string)
    account_name     = string
    region_prefix    = string
    account_name_abr = optional(string)
  })
}

variable "windows_fsx" {
  description = "Configuration for AWS FSx for Windows File System"
  type = object({
    # Required parameters
    storage_capacity    = number
    throughput_capacity = number
    subnet_ids          = list(string)

    # Optional parameters with defaults
    storage_type        = optional(string, "SSD")
    deployment_type     = optional(string, "SINGLE_AZ_2")
    preferred_subnet_id = optional(string)
    security_group_ids  = optional(list(string), [])
    kms_key_id          = optional(string)

    # Active Directory configuration
    active_directory_id = optional(string)

    # Self-managed Active Directory configuration
    self_managed_active_directory = optional(object({
      dns_ips                                = list(string)
      domain_name                            = string
      password                               = string
      username                               = string
      file_system_administrators_group       = optional(string)
      organizational_unit_distinguished_name = optional(string)
    }))

    # Backup configuration
    automatic_backup_retention_days   = optional(number, 7)
    daily_automatic_backup_start_time = optional(string)
    weekly_maintenance_start_time     = optional(string)
    copy_tags_to_backups              = optional(bool, true)
    skip_final_backup                 = optional(bool, false)

    # Audit logs configuration
    audit_log_configuration = optional(object({
      file_access_audit_log_level       = optional(string, "DISABLED")
      file_share_access_audit_log_level = optional(string, "DISABLED")
      audit_log_destination             = optional(string)
    }))

    # Disk IOPS configuration for SSD storage type
    disk_iops_configuration = optional(object({
      mode = optional(string, "AUTOMATIC")
      iops = optional(number)
    }))

    # Lifecycle
    prevent_destroy = optional(bool, true)
  })

  validation {
    condition     = var.windows_fsx.storage_capacity >= 32
    error_message = "Storage capacity must be at least 32 GiB."
  }

  validation {
    condition     = contains([8, 16, 32, 64, 128, 256, 512, 1024, 2048], var.windows_fsx.throughput_capacity)
    error_message = "Throughput capacity must be one of: 8, 16, 32, 64, 128, 256, 512, 1024, 2048."
  }

  validation {
    condition     = length(var.windows_fsx.subnet_ids) >= 1
    error_message = "At least one subnet ID must be provided."
  }

  validation {
    condition     = contains(["SSD", "HDD"], var.windows_fsx.storage_type)
    error_message = "Storage type must be either SSD or HDD."
  }

  validation {
    condition     = contains(["MULTI_AZ_1", "SINGLE_AZ_1", "SINGLE_AZ_2"], var.windows_fsx.deployment_type)
    error_message = "Deployment type must be one of: MULTI_AZ_1, SINGLE_AZ_1, SINGLE_AZ_2."
  }

  validation {
    condition     = var.windows_fsx.automatic_backup_retention_days >= 0 && var.windows_fsx.automatic_backup_retention_days <= 90
    error_message = "Automatic backup retention days must be between 0 and 90."
  }

  validation {
    condition     = var.windows_fsx.daily_automatic_backup_start_time == null || can(regex("^([01]?[0-9]|2[0-3]):[0-5][0-9]$", var.windows_fsx.daily_automatic_backup_start_time))
    error_message = "Daily automatic backup start time must be in HH:MM format (24-hour)."
  }

  validation {
    condition     = var.windows_fsx.weekly_maintenance_start_time == null || can(regex("^[1-7]:([01]?[0-9]|2[0-3]):[0-5][0-9]$", var.windows_fsx.weekly_maintenance_start_time))
    error_message = "Weekly maintenance start time must be in d:HH:MM format where d is 1-7 (Monday-Sunday)."
  }
}
