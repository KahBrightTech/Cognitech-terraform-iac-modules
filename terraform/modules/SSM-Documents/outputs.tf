#--------------------------------------------------------------------
# SSM Documents Outputs
#--------------------------------------------------------------------
output "ssm_document_name" {
  description = "Name of the SSM Document"
  value       = var.ssm_document.name
}

output "ssm_document_content" {
  description = "Content of the SSM Document"
  value       = var.ssm_document.content
}

output "ssm_document_type" {
  description = "Type of the SSM Document"
  value       = var.ssm_document.document_type
}

output "ssm_document_format" {
  description = "Format of the SSM Document"
  value       = var.ssm_document.document_format
}

output "ssm_document_tags" {
  description = "Tags of the SSM Document"
  value       = var.ssm_document.tags
}
output "ssm_document_association_created" {
  description = "Indicates if an SSM Association was created"
  value       = try(var.ssm_document.create_association, false)
}
output "ssm_document_association_name" {
  description = "Name of the SSM Association"
  value       = try(aws_ssm_association.ssm_association[0].name, null)
}
output "ssm_document_association_targets" {
  description = "Targets of the SSM Association"
  value       = try(aws_ssm_association.ssm_association[0].targets, null)
}
output "ssm_document_association_parameters" {
  description = "Parameters of the SSM Association"
  value       = try(aws_ssm_association.ssm_association[0].parameters, null)
}
