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

variable "eks_addons" {
  description = "EKS cluster addons configuration object."
  type = object({
    cluster_name                       = string
    addon_names                        = optional(string)
    create_cw_role                     = optional(bool, false)
    cloudwatch_observability_role_arn  = optional(string)
    coredns_version                    = optional(string)
    metrics_server_version             = optional(string)
    cloudwatch_observability_version   = optional(string)
    secrets_manager_csi_driver_version = optional(string)
  })

  validation {
    condition = !var.eks_addons.create_cw_role || (
      var.eks_addons.create_cw_role && var.eks_addons.cloudwatch_observability_role_arn != null
    )
    error_message = "cloudwatch_observability_role_arn must be provided when create_cw_role is true. The CloudWatch Observability addon requires a service account role ARN."
  }
}
