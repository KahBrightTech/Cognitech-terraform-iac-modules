#--------------------------------------------------------------------
# IP Set Outputs
#--------------------------------------------------------------------

output "ip_set" {
  description = "Details of the created IP set"
  value = {
    id                 = aws_wafv2_ip_set.this.id
    arn                = aws_wafv2_ip_set.this.arn
    name               = aws_wafv2_ip_set.this.name
    description        = aws_wafv2_ip_set.this.description
    scope              = aws_wafv2_ip_set.this.scope
    ip_address_version = aws_wafv2_ip_set.this.ip_address_version
    addresses          = aws_wafv2_ip_set.this.addresses
  }
}

output "ip_set_id" {
  description = "The ID of the IP set"
  value       = aws_wafv2_ip_set.this.id
}

output "ip_set_arn" {
  description = "The ARN of the IP set"
  value       = aws_wafv2_ip_set.this.arn
}

output "ip_set_name" {
  description = "The name of the IP set"
  value       = aws_wafv2_ip_set.this.name
}

output "ip_set_scope" {
  description = "The scope of the IP set"
  value       = aws_wafv2_ip_set.this.scope
}

output "ip_set_addresses" {
  description = "The IP addresses in the IP set"
  value       = aws_wafv2_ip_set.this.addresses
}

output "ip_set_address_version" {
  description = "The IP address version of the IP set"
  value       = aws_wafv2_ip_set.this.ip_address_version
}


#--------------------------------------------------------------------
# Summary Outputs
#--------------------------------------------------------------------
output "ip_set_summary" {
  description = "Summary of the IP set configuration"
  value = {
    name            = var.ip_set.name
    addresses_count = length(var.ip_set.addresses)
    address_version = var.ip_set.ip_address_version
    scope           = var.ip_set.scope
    description     = var.ip_set.description
  }
}

