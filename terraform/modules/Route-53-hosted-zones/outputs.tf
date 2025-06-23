#--------------------------------------------------------------------
# Route 53 Hosted Zones Outputs
#--------------------------------------------------------------------
output "zone_name" {
  description = "The name of the Route 53 hosted zone"
  value       = aws_route53_zone.zones.name
}

output "zone_id" {
  description = "The ID of the Route 53 hosted zone"
  value       = aws_route53_zone.zones.zone_id
}
