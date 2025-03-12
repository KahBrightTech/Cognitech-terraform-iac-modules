#--------------------------------------------------------
# NAT Gateway Outputs
#--------------------------------------------------------
output "ngw_gateway_primary_id" {
  description = "value of the primary nat gateway id"
  value       = length(aws_nat_gateway.primary) > 0 ? aws_nat_gateway.primary[0].id : null
}

output "ngw_primary_public_ip" {
  description = "value of the primary nat gateway public ip"
  value       = length(aws_nat_gateway.primary) > 0 ? aws_nat_gateway.primary[0].public_ip : null
}

output "ngw_secondary_id" {
  description = "value of the secondary nat gateway id"
  value       = length(aws_nat_gateway.secondary) > 0 ? aws_nat_gateway.secondary[0].id : null
}

output "ngw_secondary_public_ip" {
  description = "value of the secondary nat gateway public ip"
  value       = length(aws_nat_gateway.secondary) > 0 ? aws_nat_gateway.secondary[0].public_ip : null
}

output "ngw_tertiary_id" {
  description = "value of the tertiary nat gateway id"
  value       = length(aws_nat_gateway.tertiary) > 0 ? aws_nat_gateway.tertiary[0].id : null
}

output "ngw_tertiary_public_ip" {
  description = "value of the tertiary nat gateway public ip"
  value       = length(aws_nat_gateway.tertiary) > 0 ? aws_nat_gateway.tertiary[0].public_ip : null
}
