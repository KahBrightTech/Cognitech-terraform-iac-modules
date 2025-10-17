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



