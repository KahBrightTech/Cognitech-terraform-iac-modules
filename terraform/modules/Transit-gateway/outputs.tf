#--------------------------------------------------------
# Transit Gateway Outputs
#--------------------------------------------------------
output "transit_gateway_id" {
  description = "The ID of the Transit Gateway"
  value       = aws_ec2_transit_gateway.main.id
}


