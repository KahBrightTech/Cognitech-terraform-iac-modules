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
    name                                        = string
    role_arn                                    = string
    subnet_ids                                  = list(string)
    version                                     = optional(string, "1.32")
    oidc_thumbprint                             = optional(string)
    is_this_ec2_node_group                      = optional(bool, false)
    enable_networking_addons                    = optional(bool, true)
    enable_application_addons                   = optional(bool, false)
    endpoint_private_access                     = optional(bool, false)
    endpoint_public_access                      = optional(bool, true)
    public_access_cidrs                         = optional(list(string), ["0.0.0.0/0"])
    authentication_mode                         = optional(string, "API_AND_CONFIG_MAP")
    bootstrap_cluster_creator_admin_permissions = optional(bool, true)
    enabled_cluster_log_types                   = optional(list(string), [])
    key_pair = object({
      name               = optional(string)
      name_prefix        = optional(string)
      secret_name        = optional(string)
      secret_description = optional(string)
      policy             = optional(string)
      create_secret      = bool
    })
  })
}
