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

variable "eks_service_account" {
  description = "EKS service account configuration object."
  type = object({
    name      = string
    namespace = optional(string, "default")
    role_arn  = optional(string)
  })
}
