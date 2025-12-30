
output "service_account_name" {
  description = "The name of the EKS service account."
  value       = kubernetes_service_account.irsa.metadata[0].name
}

output "service_account_namespace" {
  description = "The namespace of the EKS service account."
  value       = kubernetes_service_account.irsa.metadata[0].namespace
}

output "service_account_role_arn" {
  description = "The IAM role ARN associated with the service account (IRSA only)."
  value       = try(kubernetes_service_account.irsa.metadata[0].annotations["eks.amazonaws.com/role-arn"], null)
}
