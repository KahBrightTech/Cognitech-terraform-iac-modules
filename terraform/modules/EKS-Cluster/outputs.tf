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
