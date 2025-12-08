
output "eks_cluster_certificate_authority_data" {
  description = "The certificate authority data for the EKS cluster."
  value       = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}
output "eks_cluster_id" {
  description = "EKS Cluster name."
  value       = aws_eks_cluster.eks_cluster.id
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


output "name" {
  description = "The name of the generated key pair"
  value       = length(aws_key_pair.generated_key) > 0 ? aws_key_pair.generated_key[0].key_name : null
}


output "secret_arn" {
  description = "The ARN of the created Secrets Manager secret (if created)"
  value       = length(aws_secretsmanager_secret.private_key_secret) > 0 ? aws_secretsmanager_secret.private_key_secret[0].arn : null
}