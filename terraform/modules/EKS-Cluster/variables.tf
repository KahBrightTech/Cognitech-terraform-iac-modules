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
    name                           = string
    role_arn                       = string
    subnet_ids                     = list(string)
    additional_security_group_ids  = optional(list(string), [])
    additional_security_group_keys = optional(list(string), [])
    create_ec2_node_group          = optional(bool, true)
    access_entries = optional(map(object({
      principal_arns = list(string)
      policy_arn     = string
    })), {})
    version                           = optional(string, "1.32")
    oidc_thumbprint                   = optional(string)
    is_this_ec2_node_group            = optional(bool, false)
    enable_networking_addons          = optional(bool, true)
    enable_application_addons         = optional(bool, false)
    enable_cloudwatch_observability   = optional(bool, false)
    enable_secrets_manager_csi_driver = optional(bool, false)
    # enable_helm_secrets_store_csi_driver        = optional(bool, false)
    # helm_secrets_store_csi_driver_version       = optional(string, "1.5.5")
    # helm_aws_provider_version                   = optional(string, "2.1.1")
    # helm_enableSecretRotation                   = optional(bool, true)
    # helm_rotationPollInterval                   = optional(string, "2m")
    enable_privateca_issuer                     = optional(bool, false)
    vpc_cni_version                             = optional(string, null)
    kube_proxy_version                          = optional(string, null)
    coredns_version                             = optional(string, null)
    metrics_server_version                      = optional(string, null)
    cloudwatch_observability_version            = optional(string, null)
    cloudwatch_observability_role_arn           = optional(string, null)
    secrets_manager_csi_driver_version          = optional(string, null)
    privateca_issuer_version                    = optional(string, null)
    endpoint_private_access                     = optional(bool, false)
    endpoint_public_access                      = optional(bool, true)
    public_access_cidrs                         = optional(list(string), ["0.0.0.0/0"])
    authentication_mode                         = optional(string, "API_AND_CONFIG_MAP")
    bootstrap_cluster_creator_admin_permissions = optional(bool, true)
    enabled_cluster_log_types                   = optional(list(string), [])
    service_ipv4_cidr                           = optional(string, null)

    key_pair = object({
      name               = optional(string)
      name_prefix        = optional(string)
      secret_name        = optional(string)
      secret_description = optional(string)
      policy             = optional(string)
      create_secret      = bool
    })
    security_groups = optional(list(object({
      key         = optional(string)
      name        = optional(string)
      name_prefix = optional(string)
      vpc_id      = optional(string)
      description = optional(string)
      vpc_name    = string
      security_group_egress_rules = optional(list(object({
        description     = optional(string)
        from_port       = optional(number)
        to_port         = optional(number)
        protocol        = optional(string)
        security_groups = optional(list(string))
        cidr_blocks     = list(string)
        self            = optional(bool, false)
      })))
      security_group_ingress_rules = optional(list(object({
        description     = optional(string)
        from_port       = optional(number)
        to_port         = optional(number)
        protocol        = optional(string)
        security_groups = optional(list(string))
        cidr_blocks     = list(string)
        self            = optional(bool, false)
      })))
    })))
    security_group_rules = optional(list(object({
      key               = optional(string)
      security_group_id = optional(string)
      sg_key            = optional(string)
      egress_rules = optional(list(object({
        key            = string
        cidr_ipv4      = optional(string)
        cidr_ipv6      = optional(string)
        prefix_list_id = optional(string)
        description    = optional(string)
        from_port      = optional(number)
        to_port        = optional(number)
        ip_protocol    = string
        target_sg_id   = optional(string)
        target_sg_key  = optional(string)
      })))
      ingress_rules = optional(list(object({
        key            = string
        cidr_ipv4      = optional(string)
        cidr_ipv6      = optional(string)
        prefix_list_id = optional(string)
        description    = optional(string)
        from_port      = optional(number)
        to_port        = optional(number)
        ip_protocol    = string
        source_sg_id   = optional(string)
        source_sg_key  = optional(string)
      })))
    })))
    eks_node_groups = optional(list(object({
      key                       = string
      cluster_name              = string
      node_group_name           = optional(string)
      node_role_arn             = optional(string)
      subnet_key                = optional(string)
      subnet_ids                = optional(list(string))
      desired_size              = number
      max_size                  = number
      min_size                  = number
      instance_types            = list(string)
      enable_remote_access      = optional(bool, false)
      ec2_ssh_key               = optional(string, "")
      source_security_group_ids = optional(list(string), [])
      ami_type                  = optional(string)
      disk_size                 = optional(number)
      labels                    = optional(map(string), {})
      tags                      = optional(map(string), {})
      version                   = optional(string)
      force_update_version      = optional(bool, false)
      capacity_type             = optional(string, "ON_DEMAND")
      ec2_instance_name         = optional(string, "eks_node_group")
      launch_template = optional(object({
        id      = string
        version = optional(string, "$Latest")
      }))
    })))
  })

  validation {
    condition = !var.eks_cluster.enable_cloudwatch_observability || (
      var.eks_cluster.enable_cloudwatch_observability && var.eks_cluster.cloudwatch_observability_role_arn != null
    )
    error_message = "cloudwatch_observability_role_arn must be provided when enable_cloudwatch_observability is true. The CloudWatch Observability addon requires a service account role ARN."
  }
}
