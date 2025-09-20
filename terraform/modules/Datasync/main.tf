#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#--------------------------------------------------------------------
# CloudWatch Log Group (Optional)
#--------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "datasync" {
  count             = var.datasync.create_cloudwatch_log_group ? 1 : 0
  name              = var.datasync.cloudwatch_log_group_name != null ? "/aws/datasync/${var.datasync.cloudwatch_log_group_name}" : null
  retention_in_days = var.datasync.cloudwatch_log_retention_days

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.cloudwatch_log_group_name}-log-group"
  })
}

#--------------------------------------------------------------------
# DataSync Locations
#--------------------------------------------------------------------

# S3 Location
resource "aws_datasync_location_s3" "s3" {
  count         = var.datasync.s3_location != null ? 1 : 0
  s3_bucket_arn = var.datasync.s3_location.s3_bucket_arn
  subdirectory  = var.datasync.s3_location.subdirectory
  s3_config {
    bucket_access_role_arn = var.datasync.s3_location.bucket_access_role_arn
  }
  s3_storage_class = var.datasync.s3_location.s3_storage_class

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.location_type}-location"
  })
}

# EFS Location
resource "aws_datasync_location_efs" "efs" {
  count               = var.datasync.efs_location != null ? 1 : 0
  efs_file_system_arn = var.datasync.efs_location.efs_file_system_arn
  access_point_arn    = var.datasync.efs_location.access_point_arn
  subdirectory        = var.datasync.efs_location.subdirectory
  ec2_config {
    security_group_arns = var.datasync.efs_location.ec2_config.security_group_arns
    subnet_arn          = var.datasync.efs_location.ec2_config.subnet_arn
  }
  in_transit_encryption = var.datasync.efs_location.in_transit_encryption
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.location_type}-location"
  })
}

# FSx for Windows File System Location
resource "aws_datasync_location_fsx_windows_file_system" "fsx" {
  count               = var.datasync.fsx_windows_location != null ? 1 : 0
  fsx_filesystem_arn  = var.datasync.fsx_windows_location.fsx_filesystem_arn
  subdirectory        = var.datasync.fsx_windows_location.subdirectory
  user                = var.datasync.fsx_windows_location.user
  domain              = var.datasync.fsx_windows_location.domain
  password            = var.datasync.fsx_windows_location.password
  security_group_arns = var.datasync.fsx_windows_location.security_group_arns

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.location_type}-location"
  })
}

# FSx for Lustre Location
resource "aws_datasync_location_fsx_lustre_file_system" "lustre" {
  count               = var.datasync.fsx_lustre_location != null ? 1 : 0
  fsx_filesystem_arn  = var.datasync.fsx_lustre_location.fsx_filesystem_arn
  subdirectory        = var.datasync.fsx_lustre_location.subdirectory
  security_group_arns = var.datasync.fsx_lustre_location.security_group_arns

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.location_type}-location"
  })
}

# FSx for NetApp ONTAP Location
resource "aws_datasync_location_fsx_ontap_file_system" "ontap" {
  count                       = var.datasync.fsx_ontap_location != null ? 1 : 0
  fsx_filesystem_arn          = var.datasync.fsx_ontap_location.fsx_filesystem_arn
  subdirectory                = var.datasync.fsx_ontap_location.subdirectory
  security_group_arns         = var.datasync.fsx_ontap_location.security_group_arns
  storage_virtual_machine_arn = var.datasync.fsx_ontap_location.storage_virtual_machine_arn
  dynamic "protocol" {
    for_each = var.datasync.fsx_ontap_location.protocol != null ? [var.datasync.fsx_ontap_location.protocol] : []
    content {
      dynamic "nfs" {
        for_each = protocol.value.nfs != null ? [protocol.value.nfs] : []
        content {
          mount_options {
            version = nfs.value.mount_options.version
          }
        }
      }
      dynamic "smb" {
        for_each = protocol.value.smb != null ? [protocol.value.smb] : []
        content {
          domain   = smb.value.domain
          password = smb.value.password
          user     = smb.value.user
          mount_options {
            version = smb.value.mount_options.version
          }
        }
      }
    }
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.location_type}-${var.datasync.fsx_ontap_location.protocol}-location"
  })
}

# FSx for OpenZFS Location
resource "aws_datasync_location_fsx_openzfs_file_system" "openzfs" {
  count = var.datasync.fsx_openzfs_location != null ? 1 : 0

  fsx_filesystem_arn  = var.datasync.fsx_openzfs_location.fsx_filesystem_arn
  subdirectory        = var.datasync.fsx_openzfs_location.subdirectory
  security_group_arns = var.datasync.fsx_openzfs_location.security_group_arns
  protocol {
    nfs {
      mount_options {
        version = var.datasync.fsx_openzfs_location.protocol.nfs.mount_options.version
      }
    }
  }
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.location_type}-location"
  })
}

# NFS Location
resource "aws_datasync_location_nfs" "nfs" {
  count           = var.datasync.nfs_location != null ? 1 : 0
  server_hostname = var.datasync.nfs_location.server_hostname
  subdirectory    = var.datasync.nfs_location.subdirectory
  on_prem_config {
    agent_arns = var.datasync.nfs_location.on_prem_config.agent_arns
  }
  dynamic "mount_options" {
    for_each = var.datasync.nfs_location.mount_options != null ? [var.datasync.nfs_location.mount_options] : []
    content {
      version = mount_options.value.version
    }
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.location_type}-location"
  })
}

# SMB Location
resource "aws_datasync_location_smb" "smb" {
  count = var.datasync.smb_location != null ? 1 : 0

  agent_arns      = var.datasync.smb_location.agent_arns
  domain          = var.datasync.smb_location.domain
  password        = var.datasync.smb_location.password
  server_hostname = var.datasync.smb_location.server_hostname
  subdirectory    = var.datasync.smb_location.subdirectory
  user            = var.datasync.smb_location.user

  dynamic "mount_options" {
    for_each = var.datasync.smb_location.mount_options != null ? [var.datasync.smb_location.mount_options] : []
    content {
      version = mount_options.value.version
    }
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.location_type}-location"
  })
}

# HDFS Location
resource "aws_datasync_location_hdfs" "hdfs" {
  count = var.datasync.hdfs_location != null ? 1 : 0

  agent_arns           = var.datasync.hdfs_location.agent_arns
  authentication_type  = var.datasync.hdfs_location.authentication_type
  block_size           = var.datasync.hdfs_location.block_size
  kerberos_keytab      = var.datasync.hdfs_location.kerberos_keytab
  kerberos_krb5_conf   = var.datasync.hdfs_location.kerberos_krb5_conf
  kerberos_principal   = var.datasync.hdfs_location.kerberos_principal
  kms_key_provider_uri = var.datasync.hdfs_location.kms_key_provider_uri
  replication_factor   = var.datasync.hdfs_location.replication_factor
  simple_user          = var.datasync.hdfs_location.simple_user
  subdirectory         = var.datasync.hdfs_location.subdirectory

  dynamic "name_node" {
    for_each = var.datasync.hdfs_location.namenode_configs
    content {
      hostname = name_node.value.hostname
      port     = name_node.value.port
    }
  }

  dynamic "qop_configuration" {
    for_each = var.datasync.hdfs_location.qop_configuration != null ? [var.datasync.hdfs_location.qop_configuration] : []
    content {
      data_transfer_protection = qop_configuration.value.data_transfer_protection
      rpc_protection           = qop_configuration.value.rpc_protection
    }
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.location_type}-location"
  })
}

# Object Storage Location
resource "aws_datasync_location_object_storage" "object_storage" {
  count = var.datasync.object_storage_location != null ? 1 : 0

  agent_arns         = var.datasync.object_storage_location.agent_arns
  bucket_name        = var.datasync.object_storage_location.bucket_name
  server_hostname    = var.datasync.object_storage_location.server_hostname
  subdirectory       = var.datasync.object_storage_location.subdirectory
  access_key         = var.datasync.object_storage_location.access_key
  secret_key         = var.datasync.object_storage_location.secret_key
  server_port        = var.datasync.object_storage_location.server_port
  server_protocol    = var.datasync.object_storage_location.server_protocol
  server_certificate = var.datasync.object_storage_location.server_certificate

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.location_type}-location"
  })
}

# Azure Blob Storage Location
resource "aws_datasync_location_azure_blob" "azure_blob" {
  count = var.datasync.azure_blob_location != null ? 1 : 0

  agent_arns          = var.datasync.azure_blob_location.agent_arns
  container_url       = var.datasync.azure_blob_location.container_url
  subdirectory        = var.datasync.azure_blob_location.subdirectory
  authentication_type = var.datasync.azure_blob_location.authentication_type
  blob_type           = var.datasync.azure_blob_location.blob_type
  access_tier         = var.datasync.azure_blob_location.access_tier

  dynamic "sas_configuration" {
    for_each = var.datasync.azure_blob_location.sas_configuration != null ? [var.datasync.azure_blob_location.sas_configuration] : []
    content {
      token = sas_configuration.value.token
    }
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.location_type}-location"
  })
}

#--------------------------------------------------------------------
# DataSync Task (Optional)
#--------------------------------------------------------------------

resource "aws_datasync_task" "task" {
  count = var.datasync.task != null ? 1 : 0

  name                     = var.datasync.task.name
  source_location_arn      = var.datasync.task.source_location_arn
  destination_location_arn = var.datasync.task.destination_location_arn
  cloudwatch_log_group_arn = var.datasync.task.cloudwatch_log_group_arn != null ? var.datasync.task.cloudwatch_log_group_arn : (var.datasync.create_cloudwatch_log_group ? aws_cloudwatch_log_group.datasync[0].arn : null)

  dynamic "options" {
    for_each = var.datasync.task.options != null ? [var.datasync.task.options] : []
    content {
      atime                          = options.value.atime
      bytes_per_second               = options.value.bytes_per_second
      gid                            = options.value.gid
      log_level                      = options.value.log_level
      mtime                          = options.value.mtime
      overwrite_mode                 = options.value.overwrite_mode
      posix_permissions              = options.value.posix_permissions
      preserve_deleted_files         = options.value.preserve_deleted_files
      preserve_devices               = options.value.preserve_devices
      security_descriptor_copy_flags = options.value.security_descriptor_copy_flags
      task_queueing                  = options.value.task_queueing
      transfer_mode                  = options.value.transfer_mode
      uid                            = options.value.uid
      verify_mode                    = options.value.verify_mode
    }
  }

  dynamic "excludes" {
    for_each = var.datasync.task.excludes != null ? var.datasync.task.excludes : []
    content {
      filter_type = excludes.value.filter_type
      value       = excludes.value.value
    }
  }

  dynamic "includes" {
    for_each = var.datasync.task.includes != null ? var.datasync.task.includes : []
    content {
      filter_type = includes.value.filter_type
      value       = includes.value.value
    }
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.task.name}-task"
  })
}

# DataSync Task Schedule (if specified)
resource "aws_cloudwatch_event_rule" "datasync_schedule" {
  count = var.datasync.task != null && var.datasync.task.schedule_expression != null ? 1 : 0

  name                = "${var.datasync.task.name}-schedule"
  description         = "Schedule for DataSync task ${var.datasync.task.name}"
  schedule_expression = var.datasync.task.schedule_expression

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.task.name}-schedule"
  })
}

resource "aws_cloudwatch_event_target" "datasync_target" {
  count     = var.datasync.task != null && var.datasync.task.schedule_expression != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.datasync_schedule[0].name
  target_id = "DataSyncTaskTarget"
  arn       = aws_datasync_task.task[0].arn

  role_arn = aws_iam_role.datasync_events_role[0].arn
}

# IAM role for CloudWatch Events to execute DataSync task
resource "aws_iam_role" "datasync_events_role" {
  count = var.datasync.task != null && var.datasync.task.schedule_expression != null ? 1 : 0

  name = "${var.datasync.task.name}-events-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.datasync.task.name}-event-role"
  })
}

resource "aws_iam_role_policy" "datasync_events_policy" {
  count = var.datasync.task != null && var.datasync.task.schedule_expression != null ? 1 : 0

  name = "${var.datasync.task.name}-events-policy"
  role = aws_iam_role.datasync_events_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "datasync:StartTaskExecution"
        ]
        Resource = aws_datasync_task.task[0].arn
      }
    ]
  })
}