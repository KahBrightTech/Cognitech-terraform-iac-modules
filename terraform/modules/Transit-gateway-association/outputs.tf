#--------------------------------------------------------
# Transit Gateway Association Outputs
#--------------------------------------------------------
output "association_id" {
  description = "The transit gateway association id"
  value       = length(aws_ec2_transit_gateway_route_table_association.association) > 0 ? aws_ec2_transit_gateway_route_table_association.association[0].id : null
}

