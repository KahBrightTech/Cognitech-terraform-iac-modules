
output "eks" {
  description = "All eks cluster attributes."
  value       = aws_eks_cluster.eks_cluster
}
output "eks_cluster_certificate_authority_data" {
  description = "The certificate authority data for the EKS cluster."
  value       = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}
output "eks_cluster_id" {
  description = "EKS Cluster name."
  value       = aws_eks_cluster.eks_cluster.id
}

output "eks_cluster_name" {
  description = "EKS Cluster name."
  value       = aws_eks_cluster.eks_cluster.name
}
output "eks_cluster_endpoint" {
  description = "EKS Cluster endpoint."
  value       = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_cluster_arn" {
  description = "EKS Cluster ARN."
  value       = aws_eks_cluster.eks_cluster.arn
}

output "eks_cluster_security_group_id" {
  description = "The cluster security group ID created by EKS."
  value       = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

output "eks_cluster_oidc_issuer_url" {
  description = "The URL of the OpenID Connect identity provider."
  value       = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

output "eks_cluster_platform_version" {
  description = "The platform version for the cluster."
  value       = aws_eks_cluster.eks_cluster.platform_version
}

output "eks_cluster_status" {
  description = "The status of the EKS cluster."
  value       = aws_eks_cluster.eks_cluster.status
}

output "eks_cluster_service_ipv4_cidr" {
  description = "The CIDR block for Kubernetes service IP addresses."
  value       = try(aws_eks_cluster.eks_cluster.kubernetes_network_config[0].service_ipv4_cidr, null)
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS."
  value       = aws_iam_openid_connect_provider.eks_oidc.arn
}

output "oidc_provider_url" {
  description = "URL of the OIDC Provider for EKS."
  value       = aws_iam_openid_connect_provider.eks_oidc.url
}

output "cloudwatch_observability_addon_arn" {
  description = "ARN of the CloudWatch Observability addon."
  value       = try(aws_eks_addon.cloudwatch_observability[0].arn, null)
}

output "cloudwatch_observability_addon_version" {
  description = "Version of the CloudWatch Observability addon."
  value       = try(aws_eks_addon.cloudwatch_observability[0].addon_version, null)
}


output "name" {
  description = "The name of the generated key pair"
  value       = length(aws_key_pair.generated_key) > 0 ? aws_key_pair.generated_key[0].key_name : null
}


output "secret_arn" {
  description = "The ARN of the created Secrets Manager secret (if created)"
  value       = length(aws_secretsmanager_secret.private_key_secret) > 0 ? aws_secretsmanager_secret.private_key_secret[0].arn : null
}

output "eks_sg_id" {
  description = "Map of additional security group IDs created by the module"
  value       = { for key, sg in module.security_group : key => sg.security_group_id }
}

output "eks_sg_arns" {
  description = "Map of additional security group ARNs created by the module"
  value       = { for key, sg in module.security_group : key => sg.security_group_arn }
}

output "all_cluster_security_group_ids" {
  description = "List of all security group IDs attached to the EKS cluster (including additional ones)"
  value = concat(
    [aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id],
    var.eks_cluster.additional_security_group_ids,
    [for key in var.eks_cluster.additional_security_group_keys : module.security_group[key].security_group_id]
  )
}

output "node_group_ids" {
  description = "Map of EKS Node Group IDs"
  value       = { for k, v in module.eks_node_group : k => v.node_group_id }
}

output "node_group_arns" {
  description = "Map of EKS Node Group ARNs"
  value       = { for k, v in module.eks_node_group : k => v.node_group_arn }
}

output "node_group_statuses" {
  description = "Map of EKS Node Group statuses"
  value       = { for k, v in module.eks_node_group : k => v.node_group_status }
}

output "node_group_resources" {
  description = "Map of EKS Node Group resources"
  value       = { for k, v in module.eks_node_group : k => v.node_group_resources }
}

output "node_group_scaling_configs" {
  description = "Map of EKS Node Group scaling configs"
  value       = { for k, v in module.eks_node_group : k => v.node_group_scaling_config }
}

output "node_group_versions" {
  description = "Map of EKS Node Group Kubernetes versions"
  value       = { for k, v in module.eks_node_group : k => v.node_group_version }
}