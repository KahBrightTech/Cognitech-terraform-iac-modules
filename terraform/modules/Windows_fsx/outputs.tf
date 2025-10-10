output "id" {
  description = "The ID of the FSx Windows file system"
  value       = aws_fsx_windows_file_system.main.id
}

output "arn" {
  description = "The ARN of the FSx Windows file system"
  value       = aws_fsx_windows_file_system.main.arn
}

output "dns_name" {
  description = "The DNS name for the FSx Windows file system"
  value       = aws_fsx_windows_file_system.main.dns_name
}

output "network_interface_ids" {
  description = "Set of Elastic Network Interface identifiers from which the file system is accessible"
  value       = aws_fsx_windows_file_system.main.network_interface_ids
}

output "owner_id" {
  description = "AWS account identifier that created the file system"
  value       = aws_fsx_windows_file_system.main.owner_id
}

output "vpc_id" {
  description = "Identifier of the Virtual Private Cloud for the file system"
  value       = aws_fsx_windows_file_system.main.vpc_id
}

output "preferred_file_server_ip" {
  description = "The IP address of the primary, or preferred, file server"
  value       = aws_fsx_windows_file_system.main.preferred_file_server_ip
}

output "remote_administration_endpoint" {
  description = "For Multi-AZ file systems, the IP address of the remote administration endpoint"
  value       = aws_fsx_windows_file_system.main.remote_administration_endpoint
}

output "kms_key_id" {
  description = "ARN for the KMS Key to encrypt the file system at rest"
  value       = aws_fsx_windows_file_system.main.kms_key_id
}