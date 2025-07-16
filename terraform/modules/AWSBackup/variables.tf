variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global           = bool
    tags             = map(string)
    account_name     = string
    region_prefix    = string
    account_name_abr = optional(string)
  })
}
variable "backup" {
  description = "Backup configuration"
  type = object({
    name        = string
    kms_key_arn = optional(string) # Optional KMS key ARN for encryption
    role_name   = optional(string) # IAM role name for AWS Backup
  })
}
