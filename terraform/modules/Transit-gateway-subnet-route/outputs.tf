#--------------------------------------------------------
# Transit Gateway Association Outputs
#--------------------------------------------------------
output "subnet_route_table_id" {
  description = "The ID of the subnet route table"
  value       = length(aws_route.route) > 0 ? aws_route.route[0].id : null
}
