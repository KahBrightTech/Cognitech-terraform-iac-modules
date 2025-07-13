#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_roles" "admin_role" {
  count       = var.s3.enable_bucket_policy && var.s3.policy != null ? 1 : 0
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "network_role" {
  count       = var.s3.enable_bucket_policy && var.s3.policy != null ? 1 : 0
  name_regex  = "AWSReservedSSO_NetworkAdministrator_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

# data "aws_iam_role" "github_oidc_role" {
#   name = "prod-OIDCGitHubRole-role"
# }
data "aws_iam_roles" "github_oidc_roles" {
  count       = var.s3.enable_bucket_policy && var.s3.policy != null ? 1 : 0
  name_regex  = ".*-OIDCGitHubRole-role"
  path_prefix = "/"
}


data "aws_iam_policy_document" "default" {
  count = var.s3.enable_bucket_policy && var.s3.policy != null ? 1 : 0

  override_policy_documents = [
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    file(var.s3.policy),
                    "[[resource_name]]", aws_s3_bucket.private.id
                  ),
                  "[[account_number]]", data.aws_caller_identity.current.account_id
                ),
                "[[region]]", data.aws_region.current.name
              ),
              "[[account_name]]", var.common.account_name
            ),
            "[[bucket_arn]]", aws_s3_bucket.private.arn
          ),
          "[[admin_role]]", tolist(data.aws_iam_roles.admin_role[0].arns)[0]
        ),
        "[[network_role]]", tolist(data.aws_iam_roles.network_role[0].arns)[0]
      ),
      "[[github_oidc_role]]", tolist(data.aws_iam_roles.github_oidc_roles[0].arns)[0]
    )
  ]
}

locals {
  bucket_name = var.s3.name_override != null ? var.s3.name_override : "${var.common.account_name}-${var.common.region_prefix}-${var.s3.name}"
  s3_policy   = var.s3.enable_bucket_policy && var.s3.policy != null ? (var.s3.iam_role_arn_pattern == null ? file(var.s3.policy) : join("", [for key, value in var.s3.iam_role_arn_pattern : replace(file(var.s3.policy), key, value)])) : null
}

#--------------------------------------------------------------------
# S3 Bucket - Creates a private S3 bucket
#--------------------------------------------------------------------
resource "aws_s3_bucket" "private" {
  bucket = local.bucket_name
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.s3.name}"
    }
  )
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = local.bucket_name

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = local.bucket_name

  block_public_acls  = true
  ignore_public_acls = true
  # block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  count  = var.s3.encryption != null && var.s3.encryption.enabled ? 1 : 0
  bucket = local.bucket_name

  rule {
    bucket_key_enabled = var.s3.encryption != null ? var.s3.encryption.bucket_key_enabled : false
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.s3.encryption != null ? var.s3.encryption.sse_algorithm : "AES256"
      kms_master_key_id = var.s3.encryption != null && var.s3.encryption.sse_algorithm == "aws:kms" ? var.s3.encryption.kms_master_key_id : null
    }
  }
}

resource "aws_s3_bucket_policy" "default" {
  count  = var.s3.enable_bucket_policy && var.s3.policy != null ? 1 : 0
  bucket = local.bucket_name
  policy = data.aws_iam_policy_document.default[0].json

  # policy = var.s3.override_policy_document != null && var.s3.override_policy_document != "" ? var.s3.override_policy_document : data.aws_iam_policy_document.default.json
}
resource "aws_s3_bucket_versioning" "bucket" {
  bucket = local.bucket_name

  versioning_configuration {
    status = var.s3.enable_versioning == true ? "Enabled" : "Disabled"
  }

}

#--------------------------------------------------------------------
# S3 Bucket - Replication Configuration
#--------------------------------------------------------------------
resource "aws_s3_bucket_replication_configuration" "replication" {
  count = var.s3.replication != null ? 1 : 0

  bucket = aws_s3_bucket.private.id
  role   = var.s3.replication.role_arn

  dynamic "rule" {
    for_each = var.s3.replication.rules
    content {
      id       = "replication-rule-${count.index}"
      priority = index(var.s3.replication.rules, rule.value)
      status   = rule.value.status

      filter {
        prefix = rule.value.prefix != null ? rule.value.prefix : ""
      }

      destination {
        bucket        = rule.value.destination.bucket_arn
        storage_class = rule.value.destination.storage_class

        dynamic "encryption_configuration" {
          for_each = rule.value.destination.encryption_configuration != null ? [rule.value.destination.encryption_configuration] : []
          content {
            replica_kms_key_id = encryption_configuration.value.replica_kms_key_id
          }
        }

        dynamic "replication_time" {
          for_each = rule.value.destination.replication_time != null ? [rule.value.destination.replication_time] : []
          content {
            status = "Enabled"
            time {
              minutes = replication_time.value.minutes != null ? replication_time.value.minutes : 15
            }
          }
        }

        dynamic "metrics" {
          for_each = rule.value.destination.replica_modification != null && try(rule.value.destination.replica_modification.enabled, false) ? [rule.value.destination.replica_modification] : []
          content {
            status = metrics.value.enabled ? "Enabled" : "Disabled"
            event_threshold {
              minutes = metrics.value.metrics_event_threshold_minutes
            }
          }
        }
      }

      dynamic "delete_marker_replication" {
        for_each = rule.value.delete_marker_replication != null ? [rule.value.delete_marker_replication] : []
        content {
          status = delete_marker_replication.value ? "Enabled" : "Disabled"
        }
      }
      dynamic "source_selection_criteria" {
        for_each = rule.value.destination.encryption_configuration != null ? [1] : []
        content {
          sse_kms_encrypted_objects {
            status = "Enabled"
          }
        }
      }
    }
  }
}
