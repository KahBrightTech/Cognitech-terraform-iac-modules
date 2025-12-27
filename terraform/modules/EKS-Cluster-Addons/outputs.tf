output "coredns_addon_id" {
  description = "ID of the CoreDNS addon."
  value       = length(aws_eks_addon.coredns) > 0 ? aws_eks_addon.coredns[0].id : null
}

output "coredns_addon_version" {
  description = "Version of the CoreDNS addon."
  value       = length(aws_eks_addon.coredns) > 0 ? aws_eks_addon.coredns[0].addon_version : null
}

output "metrics_server_addon_id" {
  description = "ID of the Metrics Server addon."
  value       = length(aws_eks_addon.metrics_server) > 0 ? aws_eks_addon.metrics_server[0].id : null
}

output "metrics_server_addon_version" {
  description = "Version of the Metrics Server addon."
  value       = length(aws_eks_addon.metrics_server) > 0 ? aws_eks_addon.metrics_server[0].addon_version : null
}

output "secrets_manager_csi_driver_addon_id" {
  description = "ID of the Secrets Manager CSI Driver addon."
  value       = length(aws_eks_addon.secrets_manager_csi_driver) > 0 ? aws_eks_addon.secrets_manager_csi_driver[0].id : null
}

output "secrets_manager_csi_driver_addon_version" {
  description = "Version of the Secrets Manager CSI Driver addon."
  value       = length(aws_eks_addon.secrets_manager_csi_driver) > 0 ? aws_eks_addon.secrets_manager_csi_driver[0].addon_version : null
}