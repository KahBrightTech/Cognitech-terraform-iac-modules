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

output "validation_record_fqdns" {
  description = "FQDNs of the validation records for the ACM Certificate"
  value       = aws_acm_certificate_validation.validation.validation_record_fqdns
}

output "validation_status" {
  description = "Validation status of the ACM Certificate"
  value       = aws_acm_certificate_validation.validation.status
}

output "validation_options" {
  description = "Validation options for the ACM Certificate"
  value       = aws_acm_certificate.main.domain_validation_options
}

output "validation_arn" {
  description = "ARN of the ACM Certificate validation"
  value       = aws_acm_certificate_validation.validation.arn
}

output "validation_domain_name" {
  description = "Domain name used for validation of the ACM Certificate"
  value       = aws_acm_certificate_validation.validation.domain_name
}
