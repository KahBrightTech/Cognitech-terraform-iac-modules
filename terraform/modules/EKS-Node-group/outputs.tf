# EKS Node Group Outputs

output "node_group_id" {
  description = "EKS Node Group ID"
  value       = aws_eks_node_group.eks_node_group.id
}

output "node_group_arn" {
  description = "EKS Node Group ARN"
  value       = aws_eks_node_group.eks_node_group.arn
}

output "node_group_status" {
  description = "EKS Node Group status"
  value       = aws_eks_node_group.eks_node_group.status
}

output "node_group_resources" {
  description = "EKS Node Group resources"
  value       = aws_eks_node_group.eks_node_group.resources
}

output "node_group_scaling_config" {
  description = "EKS Node Group scaling config"
  value       = aws_eks_node_group.eks_node_group.scaling_config
}

output "node_group_version" {
  description = "EKS Node Group Kubernetes version"
  value       = aws_eks_node_group.eks_node_group.version
}
