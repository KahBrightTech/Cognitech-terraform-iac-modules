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
  description = "The private subnet variables"
  type = object({
    function_name        = string
    description          = string
    runtime              = string
    handler              = string
    timeout              = optional(number)
    private_bucklet_name = optional(string)
    lamda_s3_key         = optional(string)
    layer_description    = optional(string)
    layer_s3_key         = optional(string)
    env_variables        = optional(map(string))
  })
}
