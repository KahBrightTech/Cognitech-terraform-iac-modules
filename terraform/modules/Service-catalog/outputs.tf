output "service_catalog_id" {
  description = "The ID of the service catalog"
  value       = aws_servicecatalog_portfolio.service_catalog.id

}
output "service_catalog_name" {
  description = "The name of the service catalog"
  value       = aws_servicecatalog_portfolio.service_catalog.name
}


