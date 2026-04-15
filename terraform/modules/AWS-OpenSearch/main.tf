#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.common.account_name_abr}-${var.common.region_prefix}"
  domain_name = "${local.name_prefix}-${var.opensearch.domain_name}"
}

#--------------------------------------------------------------------
# CloudWatch Log Groups for OpenSearch
#--------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "index_slow" {
  count             = var.opensearch.log_publishing.index_slow_logs_enabled ? 1 : 0
  name              = "/aws/opensearch/${local.domain_name}/index-slow-logs"
  retention_in_days = var.opensearch.log_publishing.log_retention_days

  tags = merge(var.common.tags, {
    "Name" = "/aws/opensearch/${local.domain_name}/index-slow-logs"
  })
}

resource "aws_cloudwatch_log_group" "search_slow" {
  count             = var.opensearch.log_publishing.search_slow_logs_enabled ? 1 : 0
  name              = "/aws/opensearch/${local.domain_name}/search-slow-logs"
  retention_in_days = var.opensearch.log_publishing.log_retention_days

  tags = merge(var.common.tags, {
    "Name" = "/aws/opensearch/${local.domain_name}/search-slow-logs"
  })
}

resource "aws_cloudwatch_log_group" "es_application" {
  count             = var.opensearch.log_publishing.es_application_logs_enabled ? 1 : 0
  name              = "/aws/opensearch/${local.domain_name}/es-application-logs"
  retention_in_days = var.opensearch.log_publishing.log_retention_days

  tags = merge(var.common.tags, {
    "Name" = "/aws/opensearch/${local.domain_name}/es-application-logs"
  })
}

resource "aws_cloudwatch_log_group" "audit" {
  count             = var.opensearch.log_publishing.audit_logs_enabled ? 1 : 0
  name              = "/aws/opensearch/${local.domain_name}/audit-logs"
  retention_in_days = var.opensearch.log_publishing.log_retention_days

  tags = merge(var.common.tags, {
    "Name" = "/aws/opensearch/${local.domain_name}/audit-logs"
  })
}

#--------------------------------------------------------------------
# CloudWatch Log Resource Policy
#--------------------------------------------------------------------
resource "aws_cloudwatch_log_resource_policy" "opensearch" {
  count       = var.opensearch.log_publishing.index_slow_logs_enabled || var.opensearch.log_publishing.search_slow_logs_enabled || var.opensearch.log_publishing.es_application_logs_enabled || var.opensearch.log_publishing.audit_logs_enabled ? 1 : 0
  policy_name = "${local.domain_name}-log-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "es.amazonaws.com"
        }
        Action = [
          "logs:PutLogEvents",
          "logs:PutLogEventsBatch",
          "logs:CreateLogStream"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/opensearch/${local.domain_name}/*"
      }
    ]
  })
}

#--------------------------------------------------------------------
# OpenSearch Domain
#--------------------------------------------------------------------
resource "aws_opensearch_domain" "main" {
  domain_name    = local.domain_name
  engine_version = var.opensearch.engine_version

  #--------------------------------------------------------------------
  # Cluster Configuration
  #--------------------------------------------------------------------
  cluster_config {
    instance_type            = var.opensearch.cluster_config.instance_type
    instance_count           = var.opensearch.cluster_config.instance_count
    dedicated_master_enabled = var.opensearch.cluster_config.dedicated_master_enabled
    dedicated_master_type    = var.opensearch.cluster_config.dedicated_master_type
    dedicated_master_count   = var.opensearch.cluster_config.dedicated_master_count
    zone_awareness_enabled   = var.opensearch.cluster_config.zone_awareness_enabled
    warm_enabled             = var.opensearch.cluster_config.warm_enabled
    warm_type                = var.opensearch.cluster_config.warm_type
    warm_count               = var.opensearch.cluster_config.warm_count

    dynamic "zone_awareness_config" {
      for_each = var.opensearch.cluster_config.zone_awareness_enabled ? [1] : []
      content {
        availability_zone_count = var.opensearch.cluster_config.availability_zone_count
      }
    }
  }

  #--------------------------------------------------------------------
  # EBS Options
  #--------------------------------------------------------------------
  ebs_options {
    ebs_enabled = var.opensearch.ebs_options.ebs_enabled
    volume_type = var.opensearch.ebs_options.volume_type
    volume_size = var.opensearch.ebs_options.volume_size
    iops        = var.opensearch.ebs_options.iops
    throughput  = var.opensearch.ebs_options.throughput
  }

  #--------------------------------------------------------------------
  # Encryption
  #--------------------------------------------------------------------
  encrypt_at_rest {
    enabled    = var.opensearch.encrypt_at_rest.enabled
    kms_key_id = var.opensearch.encrypt_at_rest.kms_key_id
  }

  node_to_node_encryption {
    enabled = var.opensearch.node_to_node_encryption
  }

  #--------------------------------------------------------------------
  # Domain Endpoint Options
  #--------------------------------------------------------------------
  domain_endpoint_options {
    enforce_https                   = var.opensearch.domain_endpoint_options.enforce_https
    tls_security_policy             = var.opensearch.domain_endpoint_options.tls_security_policy
    custom_endpoint_enabled         = var.opensearch.domain_endpoint_options.custom_endpoint_enabled
    custom_endpoint                 = var.opensearch.domain_endpoint_options.custom_endpoint
    custom_endpoint_certificate_arn = var.opensearch.domain_endpoint_options.custom_endpoint_certificate_arn
  }

  #--------------------------------------------------------------------
  # VPC Options
  #--------------------------------------------------------------------
  dynamic "vpc_options" {
    for_each = var.opensearch.vpc_options != null ? [var.opensearch.vpc_options] : []
    content {
      subnet_ids         = vpc_options.value.subnet_ids
      security_group_ids = vpc_options.value.security_group_ids
    }
  }

  #--------------------------------------------------------------------
  # Advanced Security Options (Fine-Grained Access Control)
  #--------------------------------------------------------------------
  dynamic "advanced_security_options" {
    for_each = var.opensearch.advanced_security_options != null ? [var.opensearch.advanced_security_options] : []
    content {
      enabled                        = advanced_security_options.value.enabled
      anonymous_auth_enabled         = advanced_security_options.value.anonymous_auth_enabled
      internal_user_database_enabled = advanced_security_options.value.internal_user_database_enabled

      dynamic "master_user_options" {
        for_each = advanced_security_options.value.master_user_options != null ? [advanced_security_options.value.master_user_options] : []
        content {
          master_user_arn      = master_user_options.value.master_user_arn
          master_user_name     = master_user_options.value.master_user_name
          master_user_password = master_user_options.value.master_user_password
        }
      }
    }
  }

  #--------------------------------------------------------------------
  # Access Policy
  #--------------------------------------------------------------------
  access_policies = var.opensearch.access_policies

  #--------------------------------------------------------------------
  # Auto-Tune Options
  #--------------------------------------------------------------------
  dynamic "auto_tune_options" {
    for_each = var.opensearch.auto_tune_desired_state != null ? [1] : []
    content {
      desired_state = var.opensearch.auto_tune_desired_state
    }
  }

  #--------------------------------------------------------------------
  # Advanced Options
  #--------------------------------------------------------------------
  advanced_options = var.opensearch.advanced_options

  #--------------------------------------------------------------------
  # Log Publishing Options
  #--------------------------------------------------------------------
  dynamic "log_publishing_options" {
    for_each = var.opensearch.log_publishing.index_slow_logs_enabled ? [1] : []
    content {
      cloudwatch_log_group_arn = aws_cloudwatch_log_group.index_slow[0].arn
      log_type                 = "INDEX_SLOW_LOGS"
    }
  }

  dynamic "log_publishing_options" {
    for_each = var.opensearch.log_publishing.search_slow_logs_enabled ? [1] : []
    content {
      cloudwatch_log_group_arn = aws_cloudwatch_log_group.search_slow[0].arn
      log_type                 = "SEARCH_SLOW_LOGS"
    }
  }

  dynamic "log_publishing_options" {
    for_each = var.opensearch.log_publishing.es_application_logs_enabled ? [1] : []
    content {
      cloudwatch_log_group_arn = aws_cloudwatch_log_group.es_application[0].arn
      log_type                 = "ES_APPLICATION_LOGS"
    }
  }

  dynamic "log_publishing_options" {
    for_each = var.opensearch.log_publishing.audit_logs_enabled ? [1] : []
    content {
      cloudwatch_log_group_arn = aws_cloudwatch_log_group.audit[0].arn
      log_type                 = "AUDIT_LOGS"
    }
  }

  tags = merge(var.common.tags, {
    "Name" = local.domain_name
  })
}


