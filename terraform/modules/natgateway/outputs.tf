# output "ngw_id" {
#   description = "The id of the nat gateways"
#   value       = { for key, nat in aws_nat_gateway.ngw : key => nat.id }
# }

# output "nat_gateway_ids" {
#   value = { for k, v in aws_nat_gateway.nat : k => v.id }
# }


output "nat_ids" {
  description = "The Ids of the nat gateways"
  value = {
    for name, nat in aws_nat_gateway.nat :
    name => nat.id
  }
}
