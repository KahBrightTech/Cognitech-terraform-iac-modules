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

output "secret_arn" {
  description = "ARN of the optional Secrets Manager secret that stores ACM certificate metadata"
  value       = try(aws_secretsmanager_secret.acm_certificate[0].arn, null)
}

output "secret_name" {
  description = "Name of the optional Secrets Manager secret that stores ACM certificate metadata"
  value       = try(aws_secretsmanager_secret.acm_certificate[0].name, null)
}
