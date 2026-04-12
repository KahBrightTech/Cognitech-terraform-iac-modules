output "domain_arn" {
  description = "ARN of the OpenSearch domain"
  value       = aws_opensearch_domain.main.arn
}

output "domain_id" {
  description = "Unique identifier for the OpenSearch domain"
  value       = aws_opensearch_domain.main.domain_id
}

output "domain_name" {
  description = "Name of the OpenSearch domain"
  value       = aws_opensearch_domain.main.domain_name
}

output "domain_endpoint" {
  description = "Domain-specific endpoint used to submit index, search, and data upload requests"
  value       = aws_opensearch_domain.main.endpoint
}

output "dashboard_endpoint" {
  description = "Domain-specific endpoint for the OpenSearch Dashboards"
  value       = aws_opensearch_domain.main.dashboard_endpoint
}

output "vpc_endpoint_ids" {
  description = "VPC endpoint IDs if the domain is VPC-based"
  value       = try(aws_opensearch_domain.main.vpc_options[0].vpc_id, null)
}

