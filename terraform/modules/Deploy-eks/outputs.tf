#--------------------------------------------------------------------
# EKS Cluster Outputs
#--------------------------------------------------------------------
output "eks_cluster_id" {
  description = "The name/id of the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.id
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.name
}

output "eks_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = aws_eks_cluster.eks_cluster.arn
}

output "eks_cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = aws_eks_cluster.eks_cluster.version
}

output "eks_cluster_platform_version" {
  description = "The platform version for the cluster"
  value       = aws_eks_cluster.eks_cluster.platform_version
}

output "eks_cluster_status" {
  description = "Status of the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.status
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.eks_cluster.certificate_authority[0].data
  sensitive   = true
}

output "eks_cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = try(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "")
}

output "eks_cluster_vpc_config" {
  description = "VPC configuration for the EKS cluster"
  value = {
    subnet_ids              = aws_eks_cluster.eks_cluster.vpc_config[0].subnet_ids
    security_group_ids      = aws_eks_cluster.eks_cluster.vpc_config[0].security_group_ids
    endpoint_private_access = aws_eks_cluster.eks_cluster.vpc_config[0].endpoint_private_access
    endpoint_public_access  = aws_eks_cluster.eks_cluster.vpc_config[0].endpoint_public_access
    public_access_cidrs     = aws_eks_cluster.eks_cluster.vpc_config[0].public_access_cidrs
    vpc_id                  = aws_eks_cluster.eks_cluster.vpc_config[0].vpc_id
  }
}

#--------------------------------------------------------------------
# OIDC Provider Outputs
#--------------------------------------------------------------------
output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = aws_iam_openid_connect_provider.eks_oidc.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider for EKS"
  value       = aws_iam_openid_connect_provider.eks_oidc.url
}

#--------------------------------------------------------------------
# EKS Access Entry Outputs
#--------------------------------------------------------------------
output "eks_access_entries" {
  description = "Map of EKS access entries created"
  value = {
    for k, v in aws_eks_access_entry.access_entry : k => {
      cluster_name  = v.cluster_name
      principal_arn = v.principal_arn
      type          = v.type
      user_name     = v.user_name
      created_at    = v.created_at
      modified_at   = v.modified_at
    }
  }
}

output "eks_access_policy_associations" {
  description = "Map of EKS access policy associations created"
  value = {
    for k, v in aws_eks_access_policy_association.access_policy : k => {
      cluster_name  = v.cluster_name
      principal_arn = v.principal_arn
      policy_arn    = v.policy_arn
      associated_at = v.associated_at
      access_scope  = v.access_scope
    }
  }
}

#--------------------------------------------------------------------
# EKS Addon Outputs
#--------------------------------------------------------------------
output "eks_addon_vpc_cni" {
  description = "VPC CNI addon details"
  value = var.eks.eks_addons != null && var.eks.eks_addons.enable_vpc_cni ? {
    addon_name    = try(aws_eks_addon.vpc_cni[0].addon_name, null)
    addon_version = try(aws_eks_addon.vpc_cni[0].addon_version, null)
    arn           = try(aws_eks_addon.vpc_cni[0].arn, null)
  } : null
}

output "eks_addon_kube_proxy" {
  description = "Kube-proxy addon details"
  value = var.eks.eks_addons != null && var.eks.eks_addons.enable_kube_proxy ? {
    addon_name    = try(aws_eks_addon.kube_proxy[0].addon_name, null)
    addon_version = try(aws_eks_addon.kube_proxy[0].addon_version, null)
    arn           = try(aws_eks_addon.kube_proxy[0].arn, null)
  } : null
}

output "eks_addon_coredns" {
  description = "CoreDNS addon details"
  value = var.eks.eks_addons != null && var.eks.eks_addons.enable_coredns && var.eks.create_node_group ? {
    addon_name    = try(aws_eks_addon.coredns[0].addon_name, null)
    addon_version = try(aws_eks_addon.coredns[0].addon_version, null)
    arn           = try(aws_eks_addon.coredns[0].arn, null)
  } : null
}

output "eks_addon_metrics_server" {
  description = "Metrics Server addon details"
  value = var.eks.eks_addons != null && var.eks.eks_addons.enable_metrics_server && var.eks.create_node_group ? {
    addon_name    = try(aws_eks_addon.metrics_server[0].addon_name, null)
    addon_version = try(aws_eks_addon.metrics_server[0].addon_version, null)
    arn           = try(aws_eks_addon.metrics_server[0].arn, null)
  } : null
}

output "eks_addon_cloudwatch_observability" {
  description = "CloudWatch Observability addon details"
  value = var.eks.eks_addons != null && var.eks.eks_addons.enable_cloudwatch_observability && var.eks.create_node_group && (var.eks.eks_addons.cloudwatch_observability_role_arn != null || var.eks.eks_addons.cloudwatch_observability_role_key != null) ? {
    addon_name    = try(aws_eks_addon.cloudwatch_observability[0].addon_name, null)
    addon_version = try(aws_eks_addon.cloudwatch_observability[0].addon_version, null)
    arn           = try(aws_eks_addon.cloudwatch_observability[0].arn, null)
  } : null
}

# output "eks_addon_secrets_manager_csi_driver" {
#   description = "Secrets Manager CSI Driver addon details"
#   value = var.eks.eks_addons != null && var.eks.eks_addons.enable_secrets_manager_csi_driver && var.eks.create_node_group ? {
#     addon_name    = try(aws_eks_addon.secrets_manager_csi_driver[0].addon_name, null)
#     addon_version = try(aws_eks_addon.secrets_manager_csi_driver[0].addon_version, null)
#     arn           = try(aws_eks_addon.secrets_manager_csi_driver[0].arn, null)
#   } : null
# }

output "eks_addon_privateca_issuer" {
  description = "Private CA Issuer addon details"
  value = var.eks.eks_addons != null && var.eks.eks_addons.enable_privateca_issuer && var.eks.create_node_group ? {
    addon_name    = try(aws_eks_addon.privateca_issuer[0].addon_name, null)
    addon_version = try(aws_eks_addon.privateca_issuer[0].addon_version, null)
    arn           = try(aws_eks_addon.privateca_issuer[0].arn, null)
  } : null
}

#--------------------------------------------------------------------
# Key Pair Outputs
#--------------------------------------------------------------------
output "key_pair_id" {
  description = "The key pair ID"
  value       = var.eks.create_node_group ? try(aws_key_pair.generated_key[0].id, null) : null
}

output "key_pair_name" {
  description = "The key pair name"
  value       = var.eks.create_node_group ? try(aws_key_pair.generated_key[0].key_name, null) : null
}

output "key_pair_arn" {
  description = "The key pair ARN"
  value       = var.eks.create_node_group ? try(aws_key_pair.generated_key[0].arn, null) : null
}

output "key_pair_fingerprint" {
  description = "The MD5 public key fingerprint"
  value       = var.eks.create_node_group ? try(aws_key_pair.generated_key[0].fingerprint, null) : null
}

#--------------------------------------------------------------------
# Secrets Manager Outputs
#--------------------------------------------------------------------
output "private_key_secret_id" {
  description = "The ID of the Secrets Manager secret storing the private key"
  value       = var.eks.create_node_group ? try(aws_secretsmanager_secret.private_key_secret[0].id, null) : null
}

output "private_key_secret_arn" {
  description = "The ARN of the Secrets Manager secret storing the private key"
  value       = var.eks.create_node_group ? try(aws_secretsmanager_secret.private_key_secret[0].arn, null) : null
}

output "private_key_secret_name" {
  description = "The name of the Secrets Manager secret storing the private key"
  value       = var.eks.create_node_group ? try(aws_secretsmanager_secret.private_key_secret[0].name, null) : null
}

output "private_key_secret_version_id" {
  description = "The version ID of the secret version"
  value       = var.eks.create_node_group ? try(aws_secretsmanager_secret_version.private_key_secret_version[0].version_id, null) : null
  sensitive   = true
}

#--------------------------------------------------------------------
# Security Group Outputs
#--------------------------------------------------------------------
output "security_groups" {
  description = "Map of security groups created for EKS"
  value = var.eks.security_groups != null ? {
    for k, v in module.security_group : k => {
      security_group_id  = v.security_group_id
      security_group_arn = v.security_group_arn
    }
  } : {}
}

#--------------------------------------------------------------------
# Launch Template Outputs
#--------------------------------------------------------------------
output "launch_templates" {
  description = "Map of launch templates created for EKS node groups"
  value = var.eks.create_node_group && var.eks.launch_templates != null ? {
    for k, v in module.launch_template : k => {
      launch_template_id   = v.id
      launch_template_arn  = v.arn
      launch_template_name = v.name
    }
  } : {}
}

#--------------------------------------------------------------------
# EKS Node Group Outputs
#--------------------------------------------------------------------
output "eks_node_groups" {
  description = "Map of EKS node groups created"
  value = var.eks.create_node_group && var.eks.eks_node_groups != null ? {
    for k, v in module.eks_node_group : k => {
      node_group_id  = v.node_group_id
      node_group_arn = v.node_group_arn
    }
  } : {}
}

#--------------------------------------------------------------------
# Data Source Outputs
#--------------------------------------------------------------------
output "aws_caller_identity" {
  description = "AWS account details"
  value = {
    account_id = data.aws_caller_identity.current.account_id
    caller_arn = data.aws_caller_identity.current.arn
    user_id    = data.aws_caller_identity.current.user_id
  }
}

output "aws_region" {
  description = "AWS region details"
  value = {
    name        = data.aws_region.current.name
    description = data.aws_region.current.description
    endpoint    = data.aws_region.current.endpoint
  }
}

output "admin_role_arn" {
  description = "ARN of the AdministratorAccess SSO role"
  value       = local.admin_role_arn
}

output "network_role_arn" {
  description = "ARN of the NetworkAdministrator SSO role"
  value       = local.network_role_arn
}

#--------------------------------------------------------------------
# Combined Configuration Output
#--------------------------------------------------------------------
output "eks_cluster_config" {
  description = "Complete EKS cluster configuration for kubectl"
  value = {
    cluster_name              = aws_eks_cluster.eks_cluster.name
    cluster_endpoint          = aws_eks_cluster.eks_cluster.endpoint
    cluster_ca_certificate    = aws_eks_cluster.eks_cluster.certificate_authority[0].data
    cluster_security_group_id = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
    oidc_provider_arn         = aws_iam_openid_connect_provider.eks_oidc.arn
    cluster_version           = aws_eks_cluster.eks_cluster.version
    cluster_platform_version  = aws_eks_cluster.eks_cluster.platform_version
  }
  sensitive = true
}

#--------------------------------------------------------------------
# EKS Service Account Outputs
#--------------------------------------------------------------------
output "eks_service_accounts" {
  description = "Map of EKS service accounts created"
  value = var.eks.create_service_accounts && var.eks.service_accounts != null ? {
    for k, v in module.service_account : k => {
      name      = v.service_account_name
      namespace = v.service_account_namespace
    }
  } : {}
}

#--------------------------------------------------------------------
# Helm Releases Outputs
#--------------------------------------------------------------------
output "helm_aws_load_balancer_controller" {
  description = "AWS Load Balancer Controller Helm release information"
  value = var.eks.eks_addons != null && var.eks.eks_addons.enable_aws_load_balancer_controller && var.eks.create_node_group ? {
    name       = try(helm_release.aws_load_balancer_controller[0].name, null)
    namespace  = try(helm_release.aws_load_balancer_controller[0].namespace, null)
    chart      = try(helm_release.aws_load_balancer_controller[0].chart, null)
    version    = try(helm_release.aws_load_balancer_controller[0].version, null)
    status     = try(helm_release.aws_load_balancer_controller[0].status, null)
    repository = try(helm_release.aws_load_balancer_controller[0].repository, null)
  } : null
}

output "helm_secrets_store_aws_provider" {
  description = "Secrets Store AWS Provider Helm release information"
  value = var.eks.eks_addons != null && var.eks.eks_addons.enable_secrets_manager_csi_driver && var.eks.create_node_group ? {
    name       = try(helm_release.secrets_store_aws_provider[0].name, null)
    namespace  = try(helm_release.secrets_store_aws_provider[0].namespace, null)
    chart      = try(helm_release.secrets_store_aws_provider[0].chart, null)
    version    = try(helm_release.secrets_store_aws_provider[0].version, null)
    status     = try(helm_release.secrets_store_aws_provider[0].status, null)
    repository = try(helm_release.secrets_store_aws_provider[0].repository, null)
  } : null
}

output "helm_external_dns" {
  description = "External DNS Helm release information"
  value = var.eks.eks_addons != null && var.eks.eks_addons.enable_external_dns && var.eks.create_node_group ? {
    name       = try(helm_release.external_dns[0].name, null)
    namespace  = try(helm_release.external_dns[0].namespace, null)
    chart      = try(helm_release.external_dns[0].chart, null)
    version    = try(helm_release.external_dns[0].version, null)
    status     = try(helm_release.external_dns[0].status, null)
    repository = try(helm_release.external_dns[0].repository, null)
  } : null
}
