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
}

# standard_expiration_days          = 0   # Objects are already in Standard class, so no transition needed
# infrequent_access_expiration_days = 30  # Transition from Standard to Standard_IA after 30 days
# glacier_expiration_days           = 60  # Transition from Standard_IA to Glacier after 60 days
# delete_expiration_days            = 365 # Delete object after 365 days in total
