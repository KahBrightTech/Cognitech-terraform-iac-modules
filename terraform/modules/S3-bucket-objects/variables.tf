variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "s3_bucket" {
  description = "S3 bucket objects configuration"
  type = object({
    bucket_id = string
    objects = list(object({
      key    = string
      source = optional(string)
      etag   = optional(string)
      tags   = optional(map(string))
    }))
  })
  default = null
}
