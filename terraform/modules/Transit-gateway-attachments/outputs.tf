#--------------------------------------------------------
# Transit Gtaeway Outputs
#--------------------------------------------------------
output "tgw_attachment_id" {
  description = "The transit gateway attachment id"
  value       = aws_ec2_transit_gateway_vpc_attachment.tgw_main_attachment.id
}

