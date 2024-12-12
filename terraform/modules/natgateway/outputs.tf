output "ngw_id" {
  description = "The id of the nat gateways"
  value       = { for key, nat in aws_nat_gateway.ngw : key => nat.id }
}
