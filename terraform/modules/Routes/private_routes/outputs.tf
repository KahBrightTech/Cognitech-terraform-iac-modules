output "private_route_table_id" {
  description = "The id of the private route table"
  value       = aws_route_table.private.id
}
