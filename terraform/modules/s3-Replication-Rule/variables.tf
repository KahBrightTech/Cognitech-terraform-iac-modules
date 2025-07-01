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

variable "s3_replication_rule" {
  description = "S3 Replication Rule configuration"
  type = object({
    role_arn = string
    source = object({
      bucket_name = string
      prefix      = string
    })
    destination = object({
      bucket_name   = string
      storage_class = string
    })
    rule_name     = optional(string)
    storage_class = optional(string, "STANDARD")
  })
  default = null
}

