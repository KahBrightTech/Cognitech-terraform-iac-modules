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
locals {
  admin_role_arn   = length(data.aws_iam_roles.admin_role.arns) > 0 ? sort(data.aws_iam_roles.admin_role.arns)[0] : ""
  network_role_arn = length(data.aws_iam_roles.network_role.arns) > 0 ? sort(data.aws_iam_roles.network_role.arns)[0] : ""
}
#--------------------------------------------------------------------
# ECR - Elastic Container Registry
#--------------------------------------------------------------------

resource "aws_ecr_repository" "repo" {
  name                 = "${var.common.account_name}-${var.common.region_prefix}-${var.ecr.name}"
  image_tag_mutability = var.ecr.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.ecr.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.ecr.encryption_type
    kms_key         = var.ecr.kms_key_arn
  }

  force_delete = var.ecr.force_delete

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.ecr.name}"
  })
}

#--------------------------------------------------------------------
# ECR Lifecycle Policy
#--------------------------------------------------------------------

resource "aws_ecr_lifecycle_policy" "lifecycle" {
  count      = var.ecr.lifecycle_policy != null || var.ecr.lifecycle_policy_file != null ? 1 : 0
  repository = aws_ecr_repository.repo.name

  policy = var.ecr.lifecycle_policy_file != null ? (
    var.ecr.custom_lifecycle_policy ? jsonencode(jsondecode(replace(
      replace(
        replace(
          replace(
            replace(
              file(var.ecr.lifecycle_policy_file),
              "[[account_number]]", data.aws_caller_identity.current.account_id,
            ),
            "[[account_name_abr]]", var.common.account_name_abr
          ),
          "[[region]]", data.aws_region.current.name
        ),
        "[[admin_role]]", local.admin_role_arn
      ),
      "[[network_role]]", local.network_role_arn
    ))) : jsonencode(jsondecode(file(var.ecr.lifecycle_policy_file)))
  ) : var.ecr.lifecycle_policy
}

#--------------------------------------------------------------------
# ECR Repository Policy
#--------------------------------------------------------------------

resource "aws_ecr_repository_policy" "policy" {
  count      = var.ecr.repository_policy != null || var.ecr.repository_policy_file != null ? 1 : 0
  repository = aws_ecr_repository.repo.name

  policy = var.ecr.repository_policy_file != null ? (
    var.ecr.custom_repository_policy ? jsonencode(jsondecode(replace(
      replace(
        replace(
          replace(
            replace(
              file(var.ecr.repository_policy_file),
              "[[account_number]]", data.aws_caller_identity.current.account_id,
            ),
            "[[account_name_abr]]", var.common.account_name_abr
          ),
          "[[region]]", data.aws_region.current.name
        ),
        "[[admin_role]]", local.admin_role_arn
      ),
      "[[network_role]]", local.network_role_arn
    ))) : jsonencode(jsondecode(file(var.ecr.repository_policy_file)))
  ) : var.ecr.repository_policy
}

#--------------------------------------------------------------------
# ECR Replication Configuration (Optional)
#--------------------------------------------------------------------

resource "aws_ecr_replication_configuration" "replication" {
  count = var.ecr.replication_configuration != null ? 1 : 0

  replication_configuration {
    dynamic "rule" {
      for_each = var.ecr.replication_configuration.rules
      content {
        dynamic "destination" {
          for_each = rule.value.destinations
          content {
            region      = destination.value.region
            registry_id = destination.value.registry_id
          }
        }
        dynamic "repository_filter" {
          for_each = rule.value.repository_filter != null ? [rule.value.repository_filter] : []
          content {
            filter      = repository_filter.value.filter
            filter_type = repository_filter.value.filter_type
          }
        }
      }
    }
  }
}

