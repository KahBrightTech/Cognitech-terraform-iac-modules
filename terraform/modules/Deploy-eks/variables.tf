variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global           = bool
    tags             = map(string)
    account_name     = string
    region_prefix    = string
    account_name_abr = optional(string, "")
    environment_abr  = optional(string, "")
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
      principal_arns    = optional(list(string))
      policy_arn        = optional(string)
      kubernetes_groups = optional(list(string), []) # Map IAM principals to these Kubernetes groups for RBAC
    })), {})
    auth = optional(object({
      cluster_roles = optional(list(object({
        key  = string
        name = string
        rules = list(object({
          api_groups = list(string)
          resources  = list(string)
          verbs      = list(string)
        }))
        labels = optional(map(string), {})
      })), [])
      cluster_role_bindings = optional(list(object({
        key               = string
        name              = string
        cluster_role_key  = optional(string)
        cluster_role_name = optional(string)
        subjects = list(object({
          kind      = string # Options: "User", "Group", "ServiceAccount"
          name      = string
          namespace = optional(string)
          api_group = optional(string, "rbac.authorization.k8s.io") # Use "rbac.authorization.k8s.io" for User/Group, "" for ServiceAccount
        }))
        labels = optional(map(string), {})
      })), [])
      roles = optional(list(object({
        key       = string
        name      = string
        namespace = optional(string, "default")
        rules = list(object({
          api_groups = list(string)
          resources  = list(string)
          verbs      = list(string)
        }))
        labels = optional(map(string), {})
      })), [])
      role_bindings = optional(list(object({
        key       = string
        name      = string
        namespace = optional(string, "default")
        role_key  = optional(string)
        role_name = optional(string)
        subjects = list(object({
          kind      = string # Options: "User", "Group", "ServiceAccount"
          name      = string
          namespace = optional(string)
          api_group = optional(string, "rbac.authorization.k8s.io") # Use "rbac.authorization.k8s.io" for User/Group, "" for ServiceAccount
        }))
        labels = optional(map(string), {})
      })), [])
    }))
    namespaces = optional(list(object({
      name   = optional(string, "")
      labels = optional(map(string), {})
      resource_quota = optional(object({
        name      = optional(string)
        hard      = optional(map(string), {})
        scopes    = optional(list(string))
        yaml_file = optional(string) # Path to a ResourceQuota YAML file. When set, spec.hard/spec.scopes are read from the file's spec block.
      }))
    })))
    version                 = optional(string, "1.32")
    oidc_thumbprint         = optional(string)
    is_this_ec2_node_group  = optional(bool, false)
    use_private_subnets     = optional(bool, false)
    vpc_name                = optional(string)
    create_service_accounts = optional(bool, false)
    enable_eks_pia          = optional(bool, false)
    # All compute-related resources: node groups, launch templates, the node
    # key pair, Karpenter, and Cluster Autoscaler.
    compute = optional(object({
      create_node_group = optional(bool, false)
      key_pair = optional(object({
        name               = optional(string)
        name_prefix        = optional(string)
        secret_name        = optional(string)
        secret_description = optional(string)
        policy             = optional(string)
      }))
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
        taints = optional(list(object({
          key    = string
          value  = optional(string)
          effect = string # NO_SCHEDULE, PREFER_NO_SCHEDULE, or NO_EXECUTE
        })))
        tags                 = optional(map(string), {})
        version              = optional(string)
        force_update_version = optional(bool, false)
        capacity_type        = optional(string, "ON_DEMAND")
        ec2_instance_name    = optional(string, "eks_node_group")
        launch_template_key  = optional(string)
        launch_template = optional(object({
          id      = string
          version = optional(string, "$Latest")
        }))
      })))
      karpenter = optional(object({
        enabled                 = optional(bool, false)
        chart_version           = optional(string, "1.13.0")
        namespace               = optional(string, "kube-system")
        controller_role_key     = optional(string)
        controller_role_arn     = optional(string)
        node_role_key           = optional(string)
        node_role_arn           = optional(string)
        node_role_name          = optional(string)
        interruption_queue_name = optional(string)
        nodepool_manifest_file  = optional(string)
      }), {})
      cluster_autoscaler = optional(object({
        enabled  = optional(bool, false)
        version  = optional(string)
        role_arn = optional(string)
        role_key = optional(string)
      }), {})
    }), {})

    # All ingress-facing resources: nginx/gateway API ingress controllers,
    # the AWS Load Balancer Controller, External DNS, and ArgoCD's ingress.
    ingress = optional(object({
      enabled = optional(bool, false)
      nginx = optional(list(object({
        name               = string
        version            = optional(string, "4.11.2")
        timeout            = optional(number, 900)
        release_name       = optional(string)
        namespace          = optional(string)
        ingress_class_name = optional(string)
        replica_count      = optional(number, 2)
        scheme             = optional(string, "internet-facing")
        target_type        = optional(string, "ip")
        nlb_name           = optional(string)
        tls_secret = optional(object({
          name        = string
          namespace   = optional(string)
          certificate = string
          private_key = string
        }))
        ssl_cert_arn             = optional(string)
        ssl_policy               = optional(string)
        ssl_ports                = optional(list(string), [])
        subnet_ids               = optional(list(string), [])
        security_group_keys      = optional(list(string), [])
        security_group_ids       = optional(list(string), [])
        service_annotations      = optional(map(string), {})
        service_annotations_file = optional(string)
        values                   = optional(list(any), [])
      })), [])
      gateway_api = optional(object({
        version                  = optional(string, "2.6.7")
        release_name             = optional(string, "ngf")
        namespace                = optional(string, "nginx-gateway")
        gateway_class_name       = optional(string, "nginx")
        controller_name          = optional(string, "gateway.nginx.org/nginx-gateway-controller")
        nginx_replicas           = optional(number, 2)
        fabric_replicas          = optional(number, 1)
        scheme                   = optional(string, "internet-facing")
        target_type              = optional(string, "ip")
        nlb_name                 = optional(string)
        ssl_cert_arn             = optional(string)
        ssl_policy               = optional(string)
        ssl_ports                = optional(list(string), [])
        subnet_ids               = optional(list(string), [])
        security_group_keys      = optional(list(string), [])
        security_group_ids       = optional(list(string), [])
        service_annotations      = optional(map(string), {})
        service_annotations_file = optional(string)
        values                   = optional(list(any), [])
      }))
      aws_load_balancer_controller = optional(object({
        enabled  = optional(bool, false)
        version  = optional(string)
        role_arn = optional(string)
        role_key = optional(string)
      }), {})
      external_dns = optional(object({
        enabled        = optional(bool, false)
        version        = optional(string)
        role_arn       = optional(string)
        role_key       = optional(string)
        namespace      = optional(string)
        policy         = optional(string) # options are upsert-only, sync or 
        domain_filters = optional(list(string))
        sources        = optional(list(string))
        log_level      = optional(string)
      }), {})
      argocd = optional(object({
        enabled                     = optional(bool, false)
        version                     = optional(string, "8.1.2")
        release_name                = optional(string, "argocd")
        namespace                   = optional(string, "argocd")
        timeout                     = optional(number, 900)
        ha_enabled                  = optional(bool, false)
        server_insecure             = optional(bool, true)
        server_replicas             = optional(number, 2)
        admin_password_bcrypt       = optional(string)
        ingress_enabled             = optional(bool, true)
        ingress_class_name          = optional(string, "alb")
        ingress_host                = optional(string)
        ingress_extra_hosts         = optional(list(string), [])
        ingress_scheme              = optional(string, "internet-facing")
        ingress_target_type         = optional(string, "ip")
        ingress_group_name          = optional(string)
        alb_name                    = optional(string)
        certificate_arn             = optional(string)
        ssl_policy                  = optional(string)
        ingress_subnet_ids          = optional(list(string), [])
        ingress_security_group_ids  = optional(list(string), [])
        ingress_security_group_keys = optional(list(string), [])
        ingress_annotations_file    = optional(string)
        ingress_annotations         = optional(map(string), {})
        values                      = optional(list(any), [])
      }), {})
    }), {})

    # All remaining cluster addons (core networking, CSI drivers,
    # observability, cert-manager, etc.).
    addons = optional(object({
      vpc_cni = optional(object({
        enabled                  = optional(bool, false)
        version                  = optional(string)
        enable_prefix_delegation = optional(bool, false)
        warm_prefix_target       = optional(number, 1)
      }), {})
      kube_proxy = optional(object({
        enabled = optional(bool, false)
        version = optional(string)
      }), {})
      coredns = optional(object({
        enabled = optional(bool, false)
        version = optional(string)
      }), {})
      metrics_server = optional(object({
        enabled = optional(bool, false)
        version = optional(string)
      }), {})
      pod_identity_agent = optional(object({
        enabled = optional(bool, false)
        version = optional(string)
      }), {})
      cloudwatch_observability = optional(object({
        enabled  = optional(bool, false)
        version  = optional(string)
        role_arn = optional(string)
        role_key = optional(string)
      }), {})
      ebs_csi_driver = optional(object({
        enabled  = optional(bool, false)
        version  = optional(string)
        role_arn = optional(string)
        role_key = optional(string)
      }), {})
      efs_csi_driver = optional(object({
        enabled  = optional(bool, false)
        version  = optional(string)
        role_arn = optional(string)
        role_key = optional(string)
      }), {})
      fsx_csi_driver = optional(object({
        enabled  = optional(bool, false)
        version  = optional(string)
        role_arn = optional(string)
        role_key = optional(string)
      }), {})
      privateca_issuer = optional(object({
        enabled = optional(bool, false)
        version = optional(string)
      }), {})
      secrets_manager_csi_driver = optional(object({
        enabled                = optional(bool, false)
        aws_provider_version   = optional(string)
        enable_secret_rotation = optional(bool, false)
        rotation_poll_interval = optional(string)
      }), {})
      fluent_bit = optional(object({
        enabled                  = optional(bool, false)
        version                  = optional(string)
        namespace                = optional(string)
        role_arn                 = optional(string)
        role_key                 = optional(string)
        firehose_delivery_stream = optional(string)
      }), {})
      kube_prometheus_stack = optional(object({
        enabled                              = optional(bool, false)
        upgrade_install                      = optional(bool, true)
        timeout                              = optional(number, 1800)
        version                              = optional(string)
        grafana_namespace                    = optional(string)
        grafana_service_type                 = optional(string)
        grafana_ingress_enabled              = optional(bool, false)
        grafana_ingress_class_name           = optional(string)
        grafana_ingress_hosts                = optional(list(string), [])
        grafana_ingress_annotations          = optional(map(string), {})
        grafana_persistence_enabled          = optional(bool, false)
        grafana_persistence_size             = optional(string)
        grafana_persistence_storage_class    = optional(string)
        prometheus_retention                 = optional(string)
        prometheus_persistence_enabled       = optional(bool, false)
        prometheus_persistence_size          = optional(string)
        prometheus_persistence_storage_class = optional(string)
      }), {})
      kubecost = optional(object({
        enabled             = optional(bool, false)
        version             = optional(string, "2.8.7")
        namespace           = optional(string, "kubecost")
        timeout             = optional(number, 900)
        storage_class       = optional(string)
        role_arn            = optional(string)
        role_key            = optional(string)
        ingress_enabled     = optional(bool, false)
        ingress_class_name  = optional(string)
        ingress_hosts       = optional(list(string), [])
        ingress_annotations = optional(map(string), {})
        values              = optional(list(any), [])
      }), {})
      cert_manager = optional(object({
        enabled                = optional(bool, false)
        version                = optional(string, "v1.16.2")
        namespace              = optional(string, "cert-manager")
        install_crds           = optional(bool, true)
        create_cluster_issuer  = optional(bool, false)
        cluster_issuer_name    = optional(string, "letsencrypt-prod-route53")
        cluster_issuer_email   = optional(string)
        cluster_issuer_server  = optional(string, "https://acme-v02.api.letsencrypt.org/directory")
        route53_region         = optional(string)
        route53_hosted_zone_id = optional(string)
        route53_role_key       = optional(string)
        route53_role_arn       = optional(string)
      }), {})
      awx_operator = optional(object({
        enabled              = optional(bool, false)
        version              = optional(string)
        release_name         = optional(string, "awx-operator")
        namespace            = optional(string, "awx")
        service_account_name = optional(string, "awx-operator-controller-manager")
        role_arn             = optional(string)
        role_key             = optional(string)
        values               = optional(list(any), [])
        # AWX instance (the operator only reconciles this CR into an actual running AWX + UI).
        create_instance     = optional(bool, false)
        instance_name       = optional(string, "awx")
        service_type        = optional(string, "ClusterIP") # ClusterIP, LoadBalancer, or NodePort
        ingress_enabled     = optional(bool, false)
        ingress_class_name  = optional(string)
        ingress_hostname    = optional(string)
        ingress_annotations = optional(map(string), {})
        spec                = optional(any, {}) # Raw overrides merged into the AWX CR spec (e.g. admin_user, postgres_configuration_secret).
      }), {})
    }), {})
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
      taints = optional(list(object({
        key    = string
        value  = optional(string)
        effect = string # NO_SCHEDULE, PREFER_NO_SCHEDULE, or NO_EXECUTE
      })))
      tags                 = optional(map(string), {})
      version              = optional(string)
      force_update_version = optional(bool, false)
      capacity_type        = optional(string, "ON_DEMAND")
      ec2_instance_name    = optional(string, "eks_node_group")
      launch_template_key  = optional(string)
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
      service_account_name      = optional(string)
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

  validation {
    condition = !var.eks.ingress.enabled || !(
      length(var.eks.ingress.nginx) > 0 &&
      var.eks.ingress.gateway_api != null
    )
    error_message = "Configure only one ingress controller block at a time: either eks.ingress.nginx or eks.ingress.gateway_api."
  }

  validation {
    condition     = !(var.eks.compute.karpenter.enabled && var.eks.compute.cluster_autoscaler.enabled)
    error_message = "Configure only one autoscaler at a time: either eks.compute.karpenter or eks.compute.cluster_autoscaler."
  }

  default = null
}


