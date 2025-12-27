
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

output "secrets_manager_csi_driver_addon_id" {
  description = "ID of the Secrets Manager CSI Driver addon."
  value       = aws_eks_addon.secrets_manager_csi_driver.id
}

output "secrets_manager_csi_driver_addon_version" {
  description = "Version of the Secrets Manager CSI Driver addon."
  value       = aws_eks_addon.secrets_manager_csi_driver.addon_version
}


