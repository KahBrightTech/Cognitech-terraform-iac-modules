#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#--------------------------------------------------------------------
# EFS File System
#--------------------------------------------------------------------
resource "aws_efs_file_system" "efs" {
  creation_token                  = var.efs.creation_token
  performance_mode                = var.efs.performance_mode
  throughput_mode                 = var.efs.throughput_mode
  provisioned_throughput_in_mibps = var.efs.throughput_mode == "provisioned" ? var.efs.provisioned_throughput_in_mibps : null
  encrypted                       = var.efs.encrypted
  kms_key_id                      = var.efs.kms_key_id

  dynamic "lifecycle_policy" {
    for_each = var.efs.lifecycle_policy != null ? [var.efs.lifecycle_policy] : []
    content {
      transition_to_ia                    = lifecycle_policy.value.transition_to_ia
      transition_to_primary_storage_class = lifecycle_policy.value.transition_to_primary_storage_class
    }
  }
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.efs.name}-efs"
  })
}

#--------------------------------------------------------------------
# EFS Mount Targets
#--------------------------------------------------------------------
resource "aws_efs_mount_target" "mount" {
  for_each = toset(var.efs.subnet_ids)

  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = each.value
  security_groups = var.efs.security_group_ids
}

#--------------------------------------------------------------------
# EFS Access Points
#--------------------------------------------------------------------
resource "aws_efs_access_point" "access_point" {
  for_each = var.efs.access_points

  file_system_id = aws_efs_file_system.efs.id

  dynamic "posix_user" {
    for_each = each.value.posix_user != null ? [each.value.posix_user] : []
    content {
      gid            = posix_user.value.gid
      uid            = posix_user.value.uid
      secondary_gids = posix_user.value.secondary_gids
    }
  }

  dynamic "root_directory" {
    for_each = each.value.root_directory != null ? [each.value.root_directory] : []
    content {
      path = root_directory.value.path

      dynamic "creation_info" {
        for_each = root_directory.value.creation_info != null ? [root_directory.value.creation_info] : []
        content {
          owner_gid   = creation_info.value.owner_gid
          owner_uid   = creation_info.value.owner_uid
          permissions = creation_info.value.permissions
        }
      }
    }
  }


  tags = merge(
    var.common.tags,
    {
      Name = "${var.common.account_name_abr}-${var.common.region_prefix}-${var.efs.name}-efs"
    }
  )
}


