#--------------------------------------------------------------------
# VPC Endpoint Outputs
#--------------------------------------------------------------------
output "vpc_endpoint_id" {
  description = "The ID of the VPC endpoint"
  value       = aws_vpc_endpoint.main.id
}

output "vpc_endpoint_arn" {
  description = "The Amazon Resource Name (ARN) of the VPC endpoint"
  value       = aws_vpc_endpoint.main.arn
}

output "vpc_endpoint_state" {
  description = "The state of the VPC endpoint"
  value       = aws_vpc_endpoint.main.state
}

output "vpc_endpoint_dns_entry" {
  description = "The DNS entries for the VPC endpoint"
  value       = aws_vpc_endpoint.main.dns_entry
}

output "vpc_endpoint_network_interface_ids" {
  description = "One or more network interfaces for the VPC endpoint (Interface endpoints only)"
  value       = aws_vpc_endpoint.main.network_interface_ids
}

output "vpc_endpoint_owner_id" {
  description = "The ID of the AWS account that owns the VPC endpoint"
  value       = aws_vpc_endpoint.main.owner_id
}

output "vpc_endpoint_prefix_list_id" {
  description = "The prefix list ID of the exposed AWS service (Gateway endpoints only)"
  value       = aws_vpc_endpoint.main.prefix_list_id
}

output "vpc_endpoint_cidr_blocks" {
  description = "The list of CIDR blocks for the exposed AWS service (Gateway endpoints only)"
  value       = aws_vpc_endpoint.main.cidr_blocks
}

output "vpc_endpoint_tags_all" {
  description = "A map of tags assigned to the resource, including those inherited from the provider default_tags"
  value       = aws_vpc_endpoint.main.tags_all
}

#--------------------------------------------------------------------
# Computed Outputs
#--------------------------------------------------------------------
output "endpoint_type" {
  description = "The type of VPC endpoint (Gateway or Interface)"
  value       = local.service_type
}

output "endpoint_name" {
  description = "The name assigned to the VPC endpoint"
  value       = local.endpoint_name
}

output "service_type" {
  description = "The service type for the VPC endpoint"
  value       = var.vpc_endpoints.service_name
}

#--------------------------------------------------------------------
# DNS Information (Interface Endpoints)
#--------------------------------------------------------------------
output "dns_names" {
  description = "The DNS names for the VPC endpoint (Interface endpoints only)"
  value = length(aws_vpc_endpoint.main.dns_entry) > 0 ? [
    for dns in aws_vpc_endpoint.main.dns_entry : dns.dns_name
  ] : []
}

output "hosted_zone_ids" {
  description = "The hosted zone IDs for the VPC endpoint (Interface endpoints only)"
  value = length(aws_vpc_endpoint.main.dns_entry) > 0 ? [
    for dns in aws_vpc_endpoint.main.dns_entry : dns.hosted_zone_id
  ] : []
}

#--------------------------------------------------------------------
# Route Table Association Outputs (Gateway Endpoints)
#--------------------------------------------------------------------
output "route_table_association_ids" {
  description = "The IDs of the route table associations (Gateway endpoints only)"
  value = {
    for k, v in aws_vpc_endpoint_route_table_association.main : k => v.id
  }
}