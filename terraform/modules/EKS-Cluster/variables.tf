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
    name            = string
    role_arn        = string
    subnet_ids      = list(string)
    version         = optional(string, "1.32")
    oidc_thumbprint = optional(string, "06b25927c42a721631c1efd9431e648fa62e1e39")
    key_pair = object({
      is_this_ec2_node_group = bool
      name                   = optional(string)
      name_prefix            = optional(string)
      secret_name            = optional(string)
      secret_description     = optional(string)
      policy                 = optional(string)
      create_secret          = bool
    })
  })
}
