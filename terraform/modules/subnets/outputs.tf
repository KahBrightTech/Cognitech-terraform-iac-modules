output "public_subnet_ids" {
  description = "The id of the public subnets"
  value       = { for key, subnet in aws_subnet.Public_subnets : key => subnet.id }
}

output "private_subnet_ids" {
  description = "The id of the private subnets"
  value       = { for key, subnet in aws_subnet.Private_subnets : key => subnet.id }
}


