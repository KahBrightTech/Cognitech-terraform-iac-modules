output "primary_az" {
  description = "The primary availability zone"
  value       = aws_subnet.primary.availability_zone
}

output "primary_az_id" {
  description = "The primary availability zone id"
  value       = aws_subnet.primary.availability_zone_id
}

output "primary_subnet_arn" {
  description = "The arn of the primary subnet"
  value       = aws_subnet.primary.arn
}

output "primary_subnet_id" {
  description = "The id of the primary subnet"
  value       = aws_subnet.primary.id
}

output "primary_subnet_cidr" {
  description = "The CIDR block of the primary subnet"
  value       = aws_subnet.primary.cidr_block
}

output "secondary_az" {
  description = "The secondary availability zone"
  value       = aws_subnet.secondary.availability_zone
}

output "secondary_az_id" {
  description = "The secondary availability zone id"
  value       = aws_subnet.secondary.availability_zone_id
}

output "secondary_subnet_arn" {
  description = "The arn of the secondary subnet"
  value       = aws_subnet.secondary.arn
}

output "secondary_subnet_id" {
  description = "List of public subnet IDs"
  value       = aws_subnet.secondary.id
}


output "secondary_subnet_cidr" {
  description = "The CIDR block of the primary subnet"
  value       = aws_subnet.secondary.cidr_block
}

output "tertiary_az" {
  description = "The tertiary availability zone"
  value       = var.private_subnets.tertiary_cidr_block != null ? aws_subnet.tertiary[0].availability_zone : null
}

output "tertiary_az_id" {
  description = "The tertiary availability zone id"
  value       = var.private_subnets.tertiary_cidr_block != null ? aws_subnet.tertiary[0].availability_zone_id : null
}

output "tertiary_subnet_arn" {
  description = "The arn of the tertiary subnet"
  value       = var.private_subnets.tertiary_cidr_block != null ? aws_subnet.tertiary[0].arn : null
}

output "tertiary_subnet_id" {
  description = "The id of the tertiary subnet"
  value       = var.private_subnets.tertiary_cidr_block != null ? aws_subnet.tertiary[0].id : null
}

output "tertiary_subnet_cidr" {
  description = "The CIDR block of the primary subnet"
  value       = var.private_subnets.tertiary_cidr_block != null ? aws_subnet.tertiary[0].cidr_block : null
}

output "subnet_ids" {
  description = "List of private subnet IDs"
  value       = [aws_subnet.primary.id, aws_subnet.secondary.id, var.private_subnets.tertiary_cidr_block != null ? aws_subnet.tertiary[0].id : null]
}


















