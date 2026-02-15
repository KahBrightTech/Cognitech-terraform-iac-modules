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

variable "ecr" {
  description = "Elastic Container Registry configuration"
  type = object({
    name                     = string
    image_tag_mutability     = optional(string, "MUTABLE")
    scan_on_push             = optional(bool, true)
    encryption_type          = optional(string, "AES256")
    kms_key_arn              = optional(string, null)
    force_delete             = optional(bool, false)
    lifecycle_policy         = optional(string, null)
    lifecycle_policy_file    = optional(string, null)
    custom_lifecycle_policy  = optional(bool, false)
    repository_policy        = optional(string, null)
    repository_policy_file   = optional(string, null)
    custom_repository_policy = optional(bool, false)
    replication_configuration = optional(object({
      rules = list(object({
        destinations = list(object({
          region      = string
          registry_id = string
        }))
        repository_filter = optional(object({
          filter      = string
          filter_type = string
        }), null)
      }))
    }), null)
  })

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }

  validation {
    condition     = contains(["AES256", "KMS"], var.ecr.encryption_type)
    error_message = "encryption_type must be either AES256 or KMS."
  }

  validation {
    condition     = var.ecr.encryption_type == "KMS" ? var.ecr.kms_key_arn != null : true
    error_message = "kms_key_arn must be provided when encryption_type is KMS."
  }
}
