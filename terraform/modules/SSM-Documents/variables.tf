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
variable "ssm_document" {
  description = "SSM Document configuration"
  type = object({
    name               = string
    content            = string
    create_association = optional(bool, false)
    document_type      = optional(string, "Command")
    document_format    = optional(string, "YAML")
    tags               = optional(map(string))
    targets = optional(object({
      key    = string
      values = list(string)
    }))
    schedule_expression = optional(string)
    output_location = optional(object({
      s3_bucket_name = string
      s3_key_prefix  = string
    }))
  })
  default = null
}

