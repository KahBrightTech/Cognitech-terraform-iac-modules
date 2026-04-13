#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix = "${var.common.account_name}-${var.common.region_prefix}"
  stream_name = "${local.name_prefix}-${var.firehose.name}"
}

#--------------------------------------------------------------------
# CloudWatch Log Group for Firehose
#--------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "firehose" {
  count             = var.firehose.enable_cloudwatch_logging ? 1 : 0
  name              = "/aws/kinesisfirehose/${local.stream_name}"
  retention_in_days = var.firehose.cloudwatch_log_retention_days

  tags = merge(var.common.tags, {
    "Name" = "/aws/kinesisfirehose/${local.stream_name}"
  })
}

resource "aws_cloudwatch_log_stream" "firehose" {
  count          = var.firehose.enable_cloudwatch_logging ? 1 : 0
  name           = "DestinationDelivery"
  log_group_name = aws_cloudwatch_log_group.firehose[0].name
}

#--------------------------------------------------------------------
# IAM Role for Firehose
#--------------------------------------------------------------------
resource "aws_iam_role" "firehose" {
  count = var.firehose.create_cw_role ? 1 : 0
  name  = "${local.stream_name}-firehose-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.common.tags, {
    "Name" = "${local.stream_name}-cloudwatch-role"
  })
}

resource "aws_iam_role_policy" "firehose_cloudwatch" {
  count = var.firehose.create_cw_role && var.firehose.enable_cloudwatch_logging ? 1 : 0
  name  = "${local.stream_name}-cloudwatch-policy"
  role  = aws_iam_role.firehose[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.firehose[0].name}:*"
        ]
      }
    ]
  })
}

#--------------------------------------------------------------------
# Kinesis Data Firehose Delivery Stream
#--------------------------------------------------------------------
resource "aws_kinesis_firehose_delivery_stream" "main" {
  name        = local.stream_name
  destination = var.firehose.destination

  #--------------------------------------------------------------------
  # Extended S3 Destination
  #--------------------------------------------------------------------
  dynamic "extended_s3_configuration" {
    for_each = var.firehose.destination == "extended_s3" ? [1] : []
    content {
      role_arn            = var.firehose.role_arn
      bucket_arn          = var.firehose.s3_configuration.bucket_arn
      prefix              = var.firehose.s3_configuration.prefix
      error_output_prefix = var.firehose.s3_configuration.error_output_prefix
      buffering_size      = var.firehose.s3_configuration.buffering_size
      buffering_interval  = var.firehose.s3_configuration.buffering_interval
      compression_format  = var.firehose.s3_configuration.compression_format

      dynamic "cloudwatch_logging_options" {
        for_each = var.firehose.enable_cloudwatch_logging ? [1] : []
        content {
          enabled         = true
          log_group_name  = aws_cloudwatch_log_group.firehose[0].name
          log_stream_name = aws_cloudwatch_log_stream.firehose[0].name
        }
      }

      dynamic "processing_configuration" {
        for_each = var.firehose.processing_configuration != null ? [var.firehose.processing_configuration] : []
        content {
          enabled = processing_configuration.value.enabled
          dynamic "processors" {
            for_each = processing_configuration.value.processors
            content {
              type = processors.value.type
              dynamic "parameters" {
                for_each = processors.value.parameters
                content {
                  parameter_name  = parameters.value.parameter_name
                  parameter_value = parameters.value.parameter_value
                }
              }
            }
          }
        }
      }
    }
  }

  #--------------------------------------------------------------------
  # OpenSearch Destination
  #--------------------------------------------------------------------
  dynamic "opensearch_configuration" {
    for_each = var.firehose.destination == "opensearch" && var.firehose.opensearch_configuration != null ? [var.firehose.opensearch_configuration] : []
    content {
      role_arn              = var.firehose.role_arn
      domain_arn            = opensearch_configuration.value.domain_arn
      index_name            = opensearch_configuration.value.index_name
      index_rotation_period = opensearch_configuration.value.index_rotation_period
      type_name             = opensearch_configuration.value.type_name
      buffering_size        = opensearch_configuration.value.buffering_size
      buffering_interval    = opensearch_configuration.value.buffering_interval
      retry_duration        = opensearch_configuration.value.retry_duration
      s3_backup_mode        = opensearch_configuration.value.s3_backup_mode

      s3_configuration {
        role_arn            = var.firehose.role_arn
        bucket_arn          = var.firehose.s3_configuration.bucket_arn
        prefix              = var.firehose.s3_configuration.prefix
        error_output_prefix = var.firehose.s3_configuration.error_output_prefix
        buffering_size      = var.firehose.s3_configuration.buffering_size
        buffering_interval  = var.firehose.s3_configuration.buffering_interval
        compression_format  = var.firehose.s3_configuration.compression_format
      }

      dynamic "cloudwatch_logging_options" {
        for_each = var.firehose.enable_cloudwatch_logging ? [1] : []
        content {
          enabled         = true
          log_group_name  = aws_cloudwatch_log_group.firehose[0].name
          log_stream_name = aws_cloudwatch_log_stream.firehose[0].name
        }
      }

      dynamic "vpc_config" {
        for_each = opensearch_configuration.value.vpc_config != null ? [opensearch_configuration.value.vpc_config] : []
        content {
          role_arn           = var.firehose.role_arn
          subnet_ids         = vpc_config.value.subnet_ids
          security_group_ids = vpc_config.value.security_group_ids
        }
      }
    }
  }

  # Kinesis source configuration (optional)
  dynamic "kinesis_source_configuration" {
    for_each = var.firehose.kinesis_source_configuration != null ? [var.firehose.kinesis_source_configuration] : []
    content {
      kinesis_stream_arn = kinesis_source_configuration.value.kinesis_stream_arn
      role_arn           = kinesis_source_configuration.value.role_arn
    }
  }

  # Server-side encryption
  dynamic "server_side_encryption" {
    for_each = var.firehose.server_side_encryption != null ? [var.firehose.server_side_encryption] : []
    content {
      enabled  = server_side_encryption.value.enabled
      key_type = server_side_encryption.value.key_type
      key_arn  = server_side_encryption.value.key_arn
    }
  }

  tags = merge(var.common.tags, {
    "Name" = local.stream_name
  })
}


