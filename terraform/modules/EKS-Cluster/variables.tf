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

variable "eks_cluster" {
  description = "EKS cluster configuration object."
  type = object({
    name       = string
    role_arn   = string
    subnet_ids = list(string)
    version    = optional(string, "1.29")
  })
}
