# output "eip_id" {
#   description = "The elastic ip id"
#   value       = { for key, eip in aws_eip.eip : key => eip.id }
# }

output "eip_ids" {
  description = "The Elastic IP IDs"
  value = {
    for name, eip in aws_eip.eip :
    name => eip.id
  }
}
