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

variable "lambda-invocations" {
  description = "The Lambda function invocation permissions variables"
  type = object({
    function_name  = string
    statement_id   = string
    principal      = string
    source_arn     = optional(string)
    source_account = optional(string)
  })
}