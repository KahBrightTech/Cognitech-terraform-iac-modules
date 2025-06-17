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

variable "state_lock" {
  description = "DynamoDB Table for Terraform State Locking"
  type = object({
    table_name = string
    hash_key   = string
    attributes = optional(list(object({
      name = string
      type = string
    })), [])
    billing_mode = optional(string, "PAY_PER_REQUEST")
  })
  default = null
}
