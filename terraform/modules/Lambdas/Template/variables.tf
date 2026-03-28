variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
  default = null
}

variable "Lambda" {
  description = "The Lambda function variables"
  type = object({
    function_name       = string
    description         = string
    runtime             = string
    handler             = string
    timeout             = optional(number)
    private_bucket_name = string
    lambda_s3_key       = string
    layer_description   = optional(string)
    layer_s3_key        = optional(string)
    env_variables       = optional(map(string))
  })
}
