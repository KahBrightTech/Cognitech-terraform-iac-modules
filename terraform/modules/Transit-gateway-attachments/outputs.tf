#--------------------------------------------------------
# Transit Gateway Outputs
#--------------------------------------------------------
output "tgw_attachment_id" {
  description = "The transit gateway attachment id"
  value       = aws_ec2_transit_gateway_vpc_attachment.vpc_attachment.id
}

output "tgw_attachment_arn" {
  description = "The transit gateway attachment ARN"
  value       = aws_ec2_transit_gateway_vpc_attachment.vpc_attachment.arn
}

#--------------------------------------------------------
# RAM Sharing Outputs
#--------------------------------------------------------
output "ram_resource_share_arn" {
  description = "The ARN of the RAM resource share (if enabled)"
  value       = var.tgw_attachments.ram != null ? (var.tgw_attachments.ram.enabled ? aws_ram_resource_share.main[0].arn : null) : null
}

output "ram_resource_share_id" {
  description = "The ID of the RAM resource share (if enabled)"
  value       = var.tgw_attachments.ram != null ? (var.tgw_attachments.ram.enabled ? aws_ram_resource_share.main[0].id : null) : null
}

output "ram_sharing_enabled" {
  description = "Whether RAM sharing is enabled for this TGW attachment"
  value       = var.tgw_attachments.ram != null ? var.tgw_attachments.ram.enabled : false
}

