variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "s3" {
  description = "S3 bucket variables"
  type = object({
    name                     = string
    description              = string
    name_override            = optional(string)
    policy                   = optional(string)
    enable_versioning        = optional(bool, true)
    enable_bucket_policy     = optional(bool, true)
    iam_role_arn_pattern     = optional(map(string), null)
    override_policy_document = optional(string)
    encryption = optional(object({
      enabled            = optional(bool, true)
      sse_algorithm      = optional(string, "AES256")
      kms_master_key_id  = optional(string, null)
      bucket_key_enabled = optional(bool, false)
      }), {
      enabled            = true
      sse_algorithm      = "AES256"
      kms_master_key_id  = null
      bucket_key_enabled = false
    })
    lifecycle = optional(object({
      standard_expiration_days          = number
      infrequent_access_expiration_days = number
      glacier_expiration_days           = number
      delete_expiration_days            = number
    }))
    lifecycle_noncurrent = optional(object({
      standard_expiration_days          = number
      infrequent_access_expiration_days = number
      glacier_expiration_days           = number
      delete_expiration_days            = number
    }))
    objects = optional(list(object({
      key = string
    })))
    replication = optional(object({
      role_arn = string
      rules = list(object({
        status                    = string
        delete_marker_replication = optional(bool, false)
        prefix                    = optional(string, "")
        filter = optional(object({
          prefix = string
        }))
        destination = object({
          bucket_arn    = string
          storage_class = optional(string, "STANDARD")
          access_control_translation = optional(object({
            owner = string
          }))
          encryption_configuration = optional(object({
            replica_kms_key_id = string
          }))
          replication_time = optional(object({
            minutes = optional(number, 15)
          }))
          replica_modification = optional(object({
            enabled                         = optional(bool, false)
            metrics_event_threshold_minutes = optional(number, 15)
          }))
        })
      }))
    }))
  })
  default = null
  validation {
    condition     = var.s3.lifecycle != null ? (var.s3.lifecycle.standard_expiration_days != 0 && var.s3.lifecycle.infrequent_access_expiration_days != 0 && var.s3.lifecycle.glacier_expiration_days != 0 && var.s3.lifecycle.delete_expiration_days != 0) : true
    error_message = "At least one of the lifecycle rules must be set to a non-zero value."
  }
  validation {
    condition     = var.s3.lifecycle_noncurrent != null ? (var.s3.lifecycle_noncurrent.standard_expiration_days != 0 && var.s3.lifecycle_noncurrent.infrequent_access_expiration_days != 0 && var.s3.lifecycle_noncurrent.glacier_expiration_days != 0 && var.s3.lifecycle_noncurrent.delete_expiration_days != 0) : true
    error_message = "At least one of the lifecycle rules must be set to a non-zero value."
  }
  validation {
    condition = var.s3.encryption != null ? (
      var.s3.encryption.sse_algorithm == null ||
      contains(["AES256", "aws:kms"], var.s3.encryption.sse_algorithm)
    ) : true
    error_message = "Encryption algorithm must be either 'AES256' or 'aws:kms'."
  }
  validation {
    condition = var.s3.encryption != null ? (
      var.s3.encryption.sse_algorithm != "aws:kms" ||
      var.s3.encryption.kms_master_key_id != null
    ) : true
    error_message = "When using 'aws:kms' encryption, kms_master_key_id must be provided."
  }
}

# standard_expiration_days          = 0   # Objects are already in Standard class, so no transition needed
# infrequent_access_expiration_days = 30  # Transition from Standard to Standard_IA after 30 days
# glacier_expiration_days           = 60  # Transition from Standard_IA to Glacier after 60 days
# delete_expiration_days            = 365 # Delete object after 365 days in total
