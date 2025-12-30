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

variable "eks" {
  description = "EKS cluster configuration object."
  type = object({
    key                                         = string
    name                                        = string
    role_arn                                    = optional(string)
    role_key                                    = optional(string)
    subnet_ids                                  = optional(list(string))
    subnet_keys                                 = optional(list(string))
    additional_security_group_ids               = optional(list(string), [])
    additional_security_group_keys              = optional(list(string), [])
    endpoint_private_access                     = optional(bool, false)
    endpoint_public_access                      = optional(bool, true)
    public_access_cidrs                         = optional(list(string), ["0.0.0.0/0"])
    authentication_mode                         = optional(string, "API_AND_CONFIG_MAP")
    bootstrap_cluster_creator_admin_permissions = optional(bool, true)
    enabled_cluster_log_types                   = optional(list(string), [])
    service_ipv4_cidr                           = optional(string, null)
    access_entries = optional(map(object({
      principal_arns = optional(list(string))
      policy_arn     = optional(string)
    })), {})
    version                 = optional(string, "1.32")
    oidc_thumbprint         = optional(string)
    is_this_ec2_node_group  = optional(bool, false)
    use_private_subnets     = optional(bool, false)
    vpc_name                = optional(string)
    create_node_group       = optional(bool, false)
    create_service_accounts = optional(bool, false)
    enable_eks_pia          = optional(bool, false)
    eks_addons = optional(object({
      enable_vpc_cni                                  = optional(bool, false)
      enable_kube_proxy                               = optional(bool, false)
      enable_coredns                                  = optional(bool, false)
      enable_metrics_server                           = optional(bool, false)
      enable_cloudwatch_observability                 = optional(bool, false)
      enable_secrets_manager_csi_driver               = optional(bool, false)
      enable_privateca_issuer                         = optional(bool, false)
      enable_pod_identity_agent                       = optional(bool, false)
      enable_ebs_csi_driver                           = optional(bool, false)
      vpc_cni_version                                 = optional(string)
      kube_proxy_version                              = optional(string)
      coredns_version                                 = optional(string)
      metrics_server_version                          = optional(string)
      cloudwatch_observability_version                = optional(string)
      secrets_manager_csi_driver_version              = optional(string)
      pod_identity_agent_version                      = optional(string)
      ebs_csi_driver_version                          = optional(string)
      secrets_manager_csi_driver_aws_provider_version = optional(string)
      privateca_issuer_version                        = optional(string)
      cloudwatch_observability_role_arn               = optional(string)
      cloudwatch_observability_role_key               = optional(string)
      ebs_csi_driver_role_arn                         = optional(string)
      ebs_csi_driver_role_key                         = optional(string)
      enableSecretRotation                            = optional(bool, false)
      rotationPollInterval                            = optional(string)
    }))
    key_pair = object({
      name               = optional(string)
      name_prefix        = optional(string)
      secret_name        = optional(string)
      secret_description = optional(string)
      policy             = optional(string)
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
    launch_templates = optional(list(object({
      key              = optional(string)
      name             = optional(string)
      instance_profile = optional(string)
      custom_ami       = optional(string)
      ami_config = object({
        os_release_date  = optional(string)
        os_base_packages = optional(string)
      })
      instance_type               = optional(string)
      key_name                    = optional(string)
      ec2_ssh_key                 = optional(string)
      associate_public_ip_address = optional(bool)
      vpc_security_group_ids      = optional(list(string))
      vpc_security_group_keys     = optional(list(string))
      tags                        = optional(map(string))
      user_data                   = optional(string)
      volume_size                 = optional(number)
      root_device_name            = optional(string)
    })))
    eks_node_groups = optional(list(object({
      key                        = optional(string)
      cluster_key                = optional(string)
      cluster_name               = optional(string)
      node_group_name            = string
      node_role_arn              = optional(string)
      node_role_key              = optional(string)
      subnet_ids                 = optional(list(string))
      subnet_keys                = optional(list(string))
      desired_size               = number
      max_size                   = number
      min_size                   = number
      instance_types             = optional(list(string), [])
      enable_remote_access       = optional(bool, false)
      ec2_ssh_key                = optional(string, "")
      source_security_group_ids  = optional(list(string), [])
      source_security_group_keys = optional(list(string), [])
      ami_type                   = optional(string)
      disk_size                  = optional(number)
      labels                     = optional(map(string), {})
      tags                       = optional(map(string), {})
      version                    = optional(string)
      force_update_version       = optional(bool, false)
      capacity_type              = optional(string, "ON_DEMAND")
      ec2_instance_name          = optional(string, "eks_node_group")
      launch_template_key        = optional(string)
      launch_template = optional(object({
        id      = string
        version = optional(string, "$Latest")
      }))
    })))
    service_accounts = optional(list(object({
      key       = optional(string)
      name      = string
      namespace = optional(string, "default")
      role_arn  = optional(string)
      role_key  = optional(string)
    })))
    eks_pia = optional(list(object({
      key                       = optional(string)
      service_account_keys      = optional(list(string), [])
      service_account_names     = optional(list(string), [])
      service_account_namespace = optional(string)
      role_arn                  = optional(string)
      role_key                  = optional(string)
    })))
    iam_roles = optional(list(object({
      key                       = optional(string)
      name                      = string
      description               = optional(string)
      path                      = optional(string, "/")
      assume_role_policy        = optional(string)
      custom_assume_role_policy = optional(bool, true)
      force_detach_policies     = optional(bool, false)
      managed_policy_arns       = optional(list(string))
      max_session_duration      = optional(number, 3600)
      permissions_boundary      = optional(string)
      create_custom_policy      = optional(bool, true)
      service_account_name      = optional(string)
      service_account_namespace = optional(string)
      policy = optional(object({
        name          = optional(string)
        description   = optional(string)
        policy        = optional(string)
        path          = optional(string, "/")
        custom_policy = optional(bool, true)
      }))
    })))
  })
  default = null
}
