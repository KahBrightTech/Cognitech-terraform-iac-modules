output "service_catalog_portfolio_id" {
  description = "The ID of the service catalog portfolio"
  value       = aws_servicecatalog_portfolio.portfolio.id
}
output "service_catalog_portfolio_name" {
  description = "The name of the service catalog portfolio"
  value       = aws_servicecatalog_portfolio.portfolio.name
}


