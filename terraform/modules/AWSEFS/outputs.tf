output "efs_file_system_id" {
  description = "The ID of the EFS file system"
  value       = aws_efs_file_system.efs.id
}

output "efs_file_system_arn" {
  description = "The ARN of the EFS file system"
  value       = aws_efs_file_system.efs.arn
}

output "efs_file_system_dns_name" {
  description = "The DNS name of the EFS file system"
  value       = aws_efs_file_system.efs.dns_name
}

output "efs_creation_token" {
  description = "The creation token of the EFS file system"
  value       = aws_efs_file_system.efs.creation_token
}

output "efs_mount_target_ids" {
  description = "The IDs of the EFS mount targets"
  value       = { for k, v in aws_efs_mount_target.mount : k => v.id }
}

output "efs_mount_target_dns_names" {
  description = "The DNS names of the EFS mount targets"
  value       = { for k, v in aws_efs_mount_target.mount : k => v.dns_name }
}

output "efs_mount_target_network_interface_ids" {
  description = "The network interface IDs of the EFS mount targets"
  value       = { for k, v in aws_efs_mount_target.mount : k => v.network_interface_id }
}

output "efs_access_point_ids" {
  description = "The IDs of the EFS access points"
  value       = { for k, v in aws_efs_access_point.access_point : k => v.id }
}

output "efs_access_point_arns" {
  description = "The ARNs of the EFS access points"
  value       = { for k, v in aws_efs_access_point.access_point : k => v.arn }
}

output "efs" {
  description = "Complete EFS configuration and attributes"
  value = {
    file_system = {
      id                              = aws_efs_file_system.efs.id
      arn                             = aws_efs_file_system.efs.arn
      dns_name                        = aws_efs_file_system.efs.dns_name
      creation_token                  = aws_efs_file_system.efs.creation_token
      performance_mode                = aws_efs_file_system.efs.performance_mode
      throughput_mode                 = aws_efs_file_system.efs.throughput_mode
      provisioned_throughput_in_mibps = aws_efs_file_system.efs.provisioned_throughput_in_mibps
      encrypted                       = aws_efs_file_system.efs.encrypted
      kms_key_id                      = aws_efs_file_system.efs.kms_key_id
    }
    mount_targets = { for k, v in aws_efs_mount_target.mount : k => {
      id                   = v.id
      dns_name             = v.dns_name
      network_interface_id = v.network_interface_id
      subnet_id            = v.subnet_id
    } }
    access_points = { for k, v in aws_efs_access_point.access_point : k => {
      id  = v.id
      arn = v.arn
    } }
  }
}
