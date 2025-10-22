#--------------------------------------------------------
# Transit Gateway Propagation Outputs
#--------------------------------------------------------
output "propagation_id" {
  description = "The transit gateway propagation id"
  value       = length(aws_ec2_transit_gateway_route_table_propagation.propagation) > 0 ? aws_ec2_transit_gateway_route_table_propagation.propagation[0].id : null
}

