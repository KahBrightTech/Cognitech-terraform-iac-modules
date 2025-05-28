output "tgw_rtb_id" {
  description = "The ID of the Transit Gateway Route Table"
  value       = length(aws_ec2_transit_gateway_route_table.route_table) > 0 ? aws_ec2_transit_gateway_route_table.route_table[0].id : null
}
