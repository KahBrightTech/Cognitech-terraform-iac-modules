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
    timeout              = number
    private_bucklet_name = string
    s3_key               = string
    layer_description    = string
  })
}

variable "vpc_id" {
  description = "The vpc id"
  type        = string
}
