#--------------------------------------------------------------------
# RAM Resource Share Outputs
#--------------------------------------------------------------------

output "resource_share_arn" {
  description = "The ARN of the resource share"
  value       = var.ram.enabled ? aws_ram_resource_share.main[0].arn : null
}

output "resource_share_id" {
  description = "The ID of the resource share"
  value       = var.ram.enabled ? aws_ram_resource_share.main[0].id : null
}

output "resource_share_name" {
  description = "The name of the resource share"
  value       = var.ram.enabled ? aws_ram_resource_share.main[0].name : null
}

output "associated_resources" {
  description = "List of resource ARNs associated with the share"
  value       = var.ram.enabled ? var.ram.resource_arns : []
}

output "associated_principals" {
  description = "List of principals associated with the share"
  value       = var.ram.enabled ? var.ram.principals : []
}

output "allow_external_principals" {
  description = "Whether the resource share allows external principals"
  value       = var.ram.enabled ? var.ram.allow_external_principals : null
}

output "sharing_enabled" {
  description = "Whether RAM sharing is enabled"
  value       = var.ram.enabled
}