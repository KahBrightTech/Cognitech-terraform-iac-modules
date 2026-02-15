#--------------------------------------------------------------------
# ECR Repository Outputs
#--------------------------------------------------------------------

output "repository_arn" {
  description = "The ARN of the ECR repository"
  value       = aws_ecr_repository.repo.arn
}

output "repository_name" {
  description = "The name of the ECR repository"
  value       = aws_ecr_repository.repo.name
}

output "repository_registry_id" {
  description = "The registry ID where the repository was created"
  value       = aws_ecr_repository.repo.registry_id
}

output "repository_url" {
  description = "The URL of the repository (in the form aws_account_id.dkr.ecr.region.amazonaws.com/repositoryName)"
  value       = aws_ecr_repository.repo.repository_url
}

output "repository_id" {
  description = "The ID of the ECR repository"
  value       = aws_ecr_repository.repo.id
}

output "lifecycle_policy_text" {
  description = "The lifecycle policy text, if configured"
  value       = var.ecr.lifecycle_policy != null ? one(aws_ecr_lifecycle_policy.lifecycle[*].policy) : null
}

output "repository_policy_text" {
  description = "The repository policy text, if configured"
  value       = var.ecr.repository_policy != null ? one(aws_ecr_repository_policy.policy[*].policy) : null
}

