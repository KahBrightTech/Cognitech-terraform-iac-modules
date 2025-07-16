#--------------------------------------------------------------------
# ACM Public Certificates Module Outputs
#--------------------------------------------------------------------
output "name" {
  description = "Name of the ACM Certificate"
  value       = aws_acm_certificate.main.id

}

output "arn" {
  description = "ARN of the ACM Certificate"
  value       = aws_acm_certificate.main.arn
}

output "domain_name" {
  description = "Domain name of the ACM Certificate"
  value       = aws_acm_certificate.main.domain_name
}
