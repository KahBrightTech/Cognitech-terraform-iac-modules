output "private_subnet_ids" {
  description = "The id of the private subnets"
  value       = { for key, subnet in aws_subnet.private_subnets : key => subnet.id }
}

output "private_subnet_cidr_blocks" {
  description = "The CIDR blocks of the private subnets"
  value       = { for key, subnet in aws_subnet.private_subnets : key => subnet.cidr_block }
}

output "private_subnet_arns" {
  description = "The ARNs of the private subnets"
  value       = { for key, subnet in aws_subnet.private_subnets : key => subnet.arn }
}

output "private_subnet_availability_zones" {
  description = "The availability zones of the private subnets"
  value       = { for key, subnet in aws_subnet.private_subnets : key => subnet.availability_zone }
}





