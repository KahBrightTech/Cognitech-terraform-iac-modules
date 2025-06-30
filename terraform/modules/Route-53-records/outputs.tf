#--------------------------------------------------------------------
# Route 53 records outputs
#--------------------------------------------------------------------
output "record_name" {
  description = "The name of the Route 53 record"
  value       = aws_route53_record.records.name
}
output "record_zone_id" {
  description = "The zone ID of the Route 53 record"
  value       = aws_route53_record.records.zone_id
}
output "record_type" {
  description = "The type of the Route 53 record"
  value       = aws_route53_record.records.type
}
output "record_ttl" {
  description = "The TTL of the Route 53 record"
  value       = aws_route53_record.records.ttl
}
output "record_records" {
  description = "The records of the Route 53 record"
  value       = aws_route53_record.records.records
}

