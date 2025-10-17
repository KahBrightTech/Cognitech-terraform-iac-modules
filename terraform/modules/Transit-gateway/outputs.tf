#--------------------------------------------------------
# Transit Gateway Outputs
#--------------------------------------------------------
output "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.id
}

output "tgw_arn" {
  description = "The arn of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.arn
}

#--------------------------------------------------------
# RAM Sharing Outputs
#--------------------------------------------------------
output "ram_resource_share_arn" {
  description = "The ARN of the RAM resource share (if enabled)"
  value       = var.transit_gateway.ram.enabled ? aws_ram_resource_share.main[0].arn : null
}

output "ram_resource_share_id" {
  description = "The ID of the RAM resource share (if enabled)"
  value       = var.transit_gateway.ram.enabled ? aws_ram_resource_share.main[0].id : null
}

output "ram_sharing_enabled" {
  description = "Whether RAM sharing is enabled for this Transit Gateway"
  value       = var.transit_gateway.ram.enabled
}




