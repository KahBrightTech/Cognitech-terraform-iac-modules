output "public_id" {
  description = "The id of the public route table"
  value       = aws_route_table.public.id

}

output "public_secondary_id" {
  description = "The id of the secondary public route table"
  value       = aws_route_table.public_secondary.id
}


output "public_tertiary_id" {
  description = "The id of the tertiary public route table"
  value       = length(aws_route_table.public_tertiary) > 0 ? aws_route_table.public_tertiary[0].id : null
}

output "public_quaternary_id" {
  description = "The id of the quaternary public route table"
  value       = length(aws_route_table.public_quaternary) > 0 ? aws_route_table.public_quaternary[0].id : null
}
