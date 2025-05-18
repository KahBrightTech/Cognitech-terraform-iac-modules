#--------------------------------------------------------------------
# Primary public subnet outputs
#--------------------------------------------------------------------
output "primary_az" {
  description = "The primary availability zone"
  value       = { for key, value in aws_subnet.primary : key => value.availability_zone }
}

output "primary_az_id" {
  description = "The primary availability zone id"
  value       = { for key, value in aws_subnet.primary : key => value.availability_zone_id }
}

output "primary_subnet_arn" {
  description = "The arn of the primary subnet"
  value       = { for key, value in aws_subnet.primary : key => value.arn }
}

output "primary_subnet_id" {
  description = "List of public subnet IDs"
  value       = { for key, value in aws_subnet.primary : key => value.id }
}

output "primary_subnet_cidr" {
  description = "The CIDR block of the primary subnet"
  value       = { for key, value in aws_subnet.primary : key => value.cidr_block }
}

#--------------------------------------------------------------------
# Secondary public subnet outputs
#--------------------------------------------------------------------
output "secondary_az" {
  description = "The secondary availability zone"
  value       = { for key, value in aws_subnet.secondary : key => value.availability_zone }
}

output "secondary_az_id" {
  description = "The secondary availability zone id"
  value       = { for key, value in aws_subnet.secondary : key => value.availability_zone_id }
}

output "secondary_subnet_arn" {
  description = "The arn of the secondary subnet"
  value       = { for key, value in aws_subnet.secondary : key => value.arn }
}

output "secondary_subnet_id" {
  description = "List of public subnet IDs"
  value       = { for key, value in aws_subnet.secondary : key => value.id }
}

output "secondary_subnet_cidr" {
  description = "The CIDR block of the secondary subnet"
  value       = { for key, value in aws_subnet.secondary : key => value.cidr_block }
}

#--------------------------------------------------------------------
# Tertiary public subnet outputs
#--------------------------------------------------------------------
output "tertiary_az" {
  description = "The tertiary availability zone"
  value       = var.public_subnets != null && length(var.public_subnets) > 0 ? { for key, value in aws_subnet.tertiary : key => value.availability_zone } : null
}

output "tertiary_az_id" {
  description = "The tertiary availability zone id"
  value       = var.public_subnets != null && length(var.public_subnets) > 0 ? { for key, value in aws_subnet.tertiary : key => value.availability_zone_id } : null
}

output "tertiary_subnet_arn" {
  description = "The arn of the tertiary subnet"
  value       = var.public_subnets != null && length(var.public_subnets) > 0 ? { for key, value in aws_subnet.tertiary : key => value.arn } : null
}

output "tertiary_subnet_id" {
  description = "The id of the tertiary subnet"
  value       = var.public_subnets != null && length(var.public_subnets) > 0 ? { for key, value in aws_subnet.tertiary : key => value.id } : null
}

output "tertiary_subnet_cidr" {
  description = "The CIDR block of the primary subnet"
  value       = var.public_subnets != null && length(var.public_subnets) > 0 ? { for key, value in aws_subnet.tertiary : key => value.cidr_block } : null
}


#--------------------------------------------------------------------
# Quaternary public subnet outputs
#--------------------------------------------------------------------
output "quaternary_az" {
  description = "The quaternary availability zone"
  value       = var.public_subnets != null && length(var.public_subnets) > 0 ? { for key, value in aws_subnet.quaternary : key => value.availability_zone } : null
}

output "quaternary_az_id" {
  description = "The quaternary availability zone id"
  value       = var.public_subnets != null && length(var.public_subnets) > 0 ? { for key, value in aws_subnet.quaternary : key => value.availability_zone_id } : null
}

output "quaternary_subnet_arn" {
  description = "The arn of the quaternary subnet"
  value       = var.public_subnets != null && length(var.public_subnets) > 0 ? { for key, value in aws_subnet.quaternary : key => value.arn } : null
}

output "quaternary_subnet_id" {
  description = "The id of the quaternary subnet"
  value       = var.public_subnets != null && length(var.public_subnets) > 0 ? { for key, value in aws_subnet.quaternary : key => value.id } : null
}

output "quaternary_subnet_cidr" {
  description = "The CIDR block of the primary subnet"
  value       = var.public_subnets != null && length(var.public_subnets) > 0 ? { for key, value in aws_subnet.quaternary : key => value.cidr_block } : null
}

#--------------------------------------------------------------------
# All Subnet Id outputs
#--------------------------------------------------------------------

output "subnet_ids" {
  description = "List of all created subnet IDs"
  value = concat(
    values({ for key, value in aws_subnet.primary : key => value.id }),
    values({ for key, value in aws_subnet.secondary : key => value.id }),
    values({ for key, value in aws_subnet.tertiary : key => value.id }),
    values({ for key, value in aws_subnet.quaternary : key => value.id })
  )
}

















