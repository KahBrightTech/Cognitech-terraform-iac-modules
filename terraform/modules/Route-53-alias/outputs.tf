#--------------------------------------------------------------------
# Route 53 records outputs
#--------------------------------------------------------------------
output "record_name" {
  description = "The name of the Route 53 record"
  value       = length(aws_route53_record.alias) > 0 ? aws_route53_record.alias[0].name : null
}
output "record_zone_id" {
  description = "The zone ID of the Route 53 record"
  value       = length(aws_route53_record.alias) > 0 ? aws_route53_record.alias[0].zone_id : null
}
output "record_type" {
  description = "The type of the Route 53 record"
  value       = length(aws_route53_record.alias) > 0 ? aws_route53_record.alias[0].type : null
}
output "record_ttl" {
  description = "The TTL of the Route 53 record"
  value       = length(aws_route53_record.alias) > 0 ? aws_route53_record.alias[0].ttl : null
}


