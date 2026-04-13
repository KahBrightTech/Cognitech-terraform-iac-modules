variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global           = bool
    tags             = map(string)
    account_name     = string
    region_prefix    = string
    account_name_abr = optional(string, "")
  })
}

variable "firehose" {
  description = "Kinesis Data Firehose delivery stream configuration."
  type = object({
    name           = string
    destination    = optional(string, "extended_s3") # extended_s3 or opensearch
    role_arn       = string                          # IAM role ARN for Firehose to assume
    create_cw_role = optional(bool, true)            # Whether to create an IAM role for Firehose

    # CloudWatch Logging
    enable_cloudwatch_logging     = optional(bool, true)
    cloudwatch_log_retention_days = optional(number, 14)

    # S3 Configuration (required for extended_s3, also used as backup destination for opensearch)
    s3_configuration = optional(object({
      bucket_arn          = string
      prefix              = optional(string, "")
      error_output_prefix = optional(string, "errors/")
      buffering_size      = optional(number, 5)   # MB
      buffering_interval  = optional(number, 300) # seconds
      compression_format  = optional(string, "GZIP")
    }), null)

    # Processing configuration (Lambda transformation, etc.)
    processing_configuration = optional(object({
      enabled = optional(bool, true)
      processors = optional(list(object({
        type = string
        parameters = list(object({
          parameter_name  = string
          parameter_value = string
        }))
      })), [])
    }), null)

    # OpenSearch destination configuration
    opensearch_configuration = optional(object({
      domain_arn            = string
      index_name            = string
      index_rotation_period = optional(string, "OneDay") # NoRotation, OneHour, OneDay, OneWeek, OneMonth
      type_name             = optional(string, null)
      buffering_size        = optional(number, 5)   # MB
      buffering_interval    = optional(number, 300) # seconds
      retry_duration        = optional(number, 300) # seconds
      s3_backup_mode        = optional(string, "FailedDocumentsOnly")
      vpc_config = optional(object({
        subnet_ids         = list(string)
        security_group_ids = list(string)
      }), null)
    }), null)

    # Kinesis stream as source (optional)
    kinesis_source_configuration = optional(object({
      kinesis_stream_arn = string
      role_arn           = string
    }), null)

    # Server-side encryption
    server_side_encryption = optional(object({
      enabled  = optional(bool, true)
      key_type = optional(string, "AWS_OWNED_CMK") # AWS_OWNED_CMK or CUSTOMER_MANAGED_CMK
      key_arn  = optional(string, null)            # Required when key_type is CUSTOMER_MANAGED_CMK
    }), null)

    tags = optional(map(string), {})
  })
}
