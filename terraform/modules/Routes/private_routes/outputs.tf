output "private_id" {
  description = "The id of the private route table"
  value       = aws_route_table.private.id

}

output "private_secondary_id" {
  description = "The id of the secondary private route table"
  value       = aws_route_table.private_secondary.id
}

output "private_tertiary_id" {
  description = "The id of the tertiary private route table"
  value       = length(aws_route_table.private_tertiary) > 0 ? aws_route_table.private_tertiary[0].id : null
}

output "private_quaternary_id" {
  description = "The id of the quaternary private route table"
  value       = length(aws_route_table.private_quaternary) > 0 ? aws_route_table.private_quaternary[0].id : null
}
