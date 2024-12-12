output "eip_id" {
  description = "The elastic ip id"
  value       = { for key, eip in aws_eip.eip : key => eip.id }
}
