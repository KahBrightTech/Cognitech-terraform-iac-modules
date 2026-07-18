output "user_pool_id" {
  description = "ID of the Cognito user pool"
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito user pool"
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_name" {
  description = "Name of the Cognito user pool"
  value       = aws_cognito_user_pool.this.name
}

output "user_pool_endpoint" {
  description = "Endpoint of the Cognito user pool (without https://)"
  value       = aws_cognito_user_pool.this.endpoint
}

output "user_pool_domain" {
  description = "The Cognito hosted UI domain, if one was created"
  value       = try(aws_cognito_user_pool_domain.this[0].domain, null)
}

output "user_pool_domain_cloudfront_distribution" {
  description = "CloudFront distribution ARN for the Cognito-managed domain, if one was created"
  value       = try(aws_cognito_user_pool_domain.this[0].cloudfront_distribution_arn, null)
}

output "clients" {
  description = "Map of app client name to its client_id and client_secret"
  value = {
    for name, client in aws_cognito_user_pool_client.this : name => {
      id     = client.id
      secret = client.client_secret
    }
  }
  sensitive = true
}

output "resource_servers" {
  description = "Map of resource server identifier to its ID"
  value = {
    for id, rs in aws_cognito_resource_server.this : id => rs.id
  }
}

output "user_groups" {
  description = "Map of user group name to its ID"
  value = {
    for name, group in aws_cognito_user_group.this : name => group.id
  }
}

output "identity_providers" {
  description = "Map of identity provider name to its provider name (as registered in Cognito)"
  value = {
    for name, idp in aws_cognito_identity_provider.this : name => idp.provider_name
  }
}

output "identity_pool_id" {
  description = "ID of the Cognito identity pool, if created"
  value       = try(aws_cognito_identity_pool.this[0].id, null)
}

output "identity_pool_arn" {
  description = "ARN of the Cognito identity pool, if created"
  value       = try(aws_cognito_identity_pool.this[0].arn, null)
}
