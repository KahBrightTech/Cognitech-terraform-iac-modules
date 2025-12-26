
output "coredns_addon_id" {
  description = "ID of the CoreDNS addon."
  value       = aws_eks_addon.coredns.id
}

output "coredns_addon_version" {
  description = "Version of the CoreDNS addon."
  value       = aws_eks_addon.coredns.addon_version
}

output "metrics_server_addon_id" {
  description = "ID of the Metrics Server addon."
  value       = aws_eks_addon.metrics_server.id
}

output "metrics_server_addon_version" {
  description = "Version of the Metrics Server addon."
  value       = aws_eks_addon.metrics_server.addon_version
}

output "cloudwatch_observability_addon_id" {
  description = "ID of the CloudWatch Observability addon."
  value       = try(aws_eks_addon.cloudwatch_observability[0].id, null)
}

output "cloudwatch_observability_addon_version" {
  description = "Version of the CloudWatch Observability addon."
  value       = try(aws_eks_addon.cloudwatch_observability[0].addon_version, null)
}

output "cloudwatch_observability_addon_arn" {
  description = "ARN of the CloudWatch Observability addon."
  value       = try(aws_eks_addon.cloudwatch_observability[0].arn, null)
}

output "secrets_manager_csi_driver_addon_id" {
  description = "ID of the Secrets Manager CSI Driver addon."
  value       = aws_eks_addon.secrets_manager_csi_driver.id
}

output "secrets_manager_csi_driver_addon_version" {
  description = "Version of the Secrets Manager CSI Driver addon."
  value       = aws_eks_addon.secrets_manager_csi_driver.addon_version
}

output "cloudwatch_observability_addon_arn" {
  description = "ARN of the CloudWatch Observability addon."
  value       = try(aws_eks_addon.cloudwatch_observability[0].arn, null)
}

output "cloudwatch_observability_addon_version" {
  description = "Version of the CloudWatch Observability addon."
  value       = try(aws_eks_addon.cloudwatch_observability[0].addon_version, null)
}
