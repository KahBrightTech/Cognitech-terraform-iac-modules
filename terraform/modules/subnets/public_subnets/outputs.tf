output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = { for key, subnet in aws_subnet.public_subnets : key => subnet.id }
}

output "public_subnet_cidr_blocks" {
  description = "The cidr blocks of the public subnets"
  value       = { for key, subnet in aws_subnet.public_subnets : key => subnet.cidr_block }
}

output "public_subnet_arns" {
  description = "The arns of the public subnets"
  value       = { for key, subnet in aws_subnet.public_subnets : key => subnet.arn }
}

output "public_subnet_availability_zones" {
  description = "The availability zones of the public subnets"
  value       = { for key, subnet in aws_subnet.public_subnets : key => subnet.availability_zone }
}







