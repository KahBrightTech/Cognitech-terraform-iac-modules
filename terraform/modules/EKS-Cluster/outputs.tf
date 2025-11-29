
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


output "name" {
  description = "The name of the generated key pair"
  value       = length(aws_key_pair.generated_key) > 0 ? aws_key_pair.generated_key[0].key_name : null
}


output "secret_arn" {
  description = "The ARN of the created Secrets Manager secret (if created)"
  value       = length(aws_secretsmanager_secret.private_key_secret) > 0 ? aws_secretsmanager_secret.private_key_secret[0].arn : null
}