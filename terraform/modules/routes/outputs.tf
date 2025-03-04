output "public_route_table_id" {
  description = "The id of the public route table"
  value       = aws_route_table.public_route_table.id

}
output "private_route_table_id" {
  description = "The id of the private route table"
  value       = aws_route_table.private_route_table.id
}
