#--------------------------------------------------------------------
# Load Balancer Configuration
#--------------------------------------------------------------------

output "name" {
  description = "value of the Load Balancer name"
  value       = aws_lb.main.name
}
output "arn" {
  description = "value of the Load Balancer ARN"
  value       = aws_lb.main.arn
}
output "dns_name" {
  description = "value of the Load Balancer DNS name"
  value       = aws_lb.main.dns_name
}
output "zone_id" {
  description = "value of the Load Balancer zone ID"
  value       = aws_lb.main.zone_id
}
output "load_balancer_type" {
  description = "value of the Load Balancer type (application or network)"
  value       = aws_lb.main.load_balancer_type
}
output "internal" {
  description = "value of the Load Balancer internal flag"
  value       = aws_lb.main.internal
}
output "security_groups" {
  description = "value of the Load Balancer security groups"
  value       = aws_lb.main.security_groups
}
output "subnets" {
  description = "value of the Load Balancer subnets"
  value       = aws_lb.main.subnets
}
output "subnet_mappings" {
  description = "value of the Load Balancer subnet mappings"
  value       = aws_lb.main.subnet_mappings
}
output "enable_deletion_protection" {
  description = "value of the Load Balancer deletion protection flag"
  value       = aws_lb.main.enable_deletion_protection
}
output "access_logs" {
  description = "value of the Load Balancer access logs configuration"
  value       = aws_lb.main.access_logs
}
output "access_logs_bucket" {
  description = "value of the Load Balancer access logs bucket"
  value       = aws_lb.main.access_logs[0].bucket
}
output "access_logs_prefix" {
  description = "value of the Load Balancer access logs prefix"
  value       = aws_lb.main.access_logs[0].prefix
}
