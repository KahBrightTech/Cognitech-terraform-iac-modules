#--------------------------------------------------------------------

# DataSync Location Outputs
#--------------------------------------------------------------------

# S3 Location Outputs
output "s3_location_arn" {
  description = "ARN of the DataSync S3 location"
  value       = var.datasync.s3_location != null ? aws_datasync_location_s3.s3[0].arn : null
}

output "s3_location_uri" {
  description = "URI of the DataSync S3 location"
  value       = var.datasync.s3_location != null ? aws_datasync_location_s3.s3[0].uri : null
}

# EFS Location Outputs
output "efs_location_arn" {
  description = "ARN of the DataSync EFS location"
  value       = var.datasync.efs_location != null ? aws_datasync_location_efs.efs[0].arn : null
}

output "efs_location_uri" {
  description = "URI of the DataSync EFS location"
  value       = var.datasync.efs_location != null ? aws_datasync_location_efs.efs[0].uri : null
}

# FSx Windows Location Outputs
output "fsx_windows_location_arn" {
  description = "ARN of the DataSync FSx Windows location"
  value       = var.datasync.fsx_windows_location != null ? aws_datasync_location_fsx_windows_file_system.fsx[0].arn : null
}

output "fsx_windows_location_uri" {
  description = "URI of the DataSync FSx Windows location"
  value       = var.datasync.fsx_windows_location != null ? aws_datasync_location_fsx_windows_file_system.fsx[0].uri : null
}

# FSx Lustre Location Outputs
output "fsx_lustre_location_arn" {
  description = "ARN of the DataSync FSx Lustre location"
  value       = var.datasync.fsx_lustre_location != null ? aws_datasync_location_fsx_lustre_file_system.lustre[0].arn : null
}

output "fsx_lustre_location_uri" {
  description = "URI of the DataSync FSx Lustre location"
  value       = var.datasync.fsx_lustre_location != null ? aws_datasync_location_fsx_lustre_file_system.lustre[0].uri : null
}

# FSx ONTAP Location Outputs
output "fsx_ontap_location_arn" {
  description = "ARN of the DataSync FSx ONTAP location"
  value       = var.datasync.fsx_ontap_location != null ? aws_datasync_location_fsx_ontap_file_system.ontap[0].arn : null
}

output "fsx_ontap_location_uri" {
  description = "URI of the DataSync FSx ONTAP location"
  value       = var.datasync.fsx_ontap_location != null ? aws_datasync_location_fsx_ontap_file_system.ontap[0].uri : null
}

# FSx OpenZFS Location Outputs
output "fsx_openzfs_location_arn" {
  description = "ARN of the DataSync FSx OpenZFS location"
  value       = var.datasync.fsx_openzfs_location != null ? aws_datasync_location_fsx_openzfs_file_system.openzfs[0].arn : null
}

output "fsx_openzfs_location_uri" {
  description = "URI of the DataSync FSx OpenZFS location"
  value       = var.datasync.fsx_openzfs_location != null ? aws_datasync_location_fsx_openzfs_file_system.openzfs[0].uri : null
}

# NFS Location Outputs
output "nfs_location_arn" {
  description = "ARN of the DataSync NFS location"
  value       = var.datasync.nfs_location != null ? aws_datasync_location_nfs.nfs[0].arn : null
}

output "nfs_location_uri" {
  description = "URI of the DataSync NFS location"
  value       = var.datasync.nfs_location != null ? aws_datasync_location_nfs.nfs[0].uri : null
}

# SMB Location Outputs
output "smb_location_arn" {
  description = "ARN of the DataSync SMB location"
  value       = var.datasync.smb_location != null ? aws_datasync_location_smb.this[0].arn : null
}

output "smb_location_uri" {
  description = "URI of the DataSync SMB location"
  value       = var.datasync.smb_location != null ? aws_datasync_location_smb.this[0].uri : null
}

# HDFS Location Outputs
output "hdfs_location_arn" {
  description = "ARN of the DataSync HDFS location"
  value       = var.datasync.hdfs_location != null ? aws_datasync_location_hdfs.this[0].arn : null
}

output "hdfs_location_uri" {
  description = "URI of the DataSync HDFS location"
  value       = var.datasync.hdfs_location != null ? aws_datasync_location_hdfs.this[0].uri : null
}

# Object Storage Location Outputs
output "object_storage_location_arn" {
  description = "ARN of the DataSync Object Storage location"
  value       = var.datasync.object_storage_location != null ? aws_datasync_location_object_storage.this[0].arn : null
}

output "object_storage_location_uri" {
  description = "URI of the DataSync Object Storage location"
  value       = var.datasync.object_storage_location != null ? aws_datasync_location_object_storage.this[0].uri : null
}

# Azure Blob Location Outputs
output "azure_blob_location_arn" {
  description = "ARN of the DataSync Azure Blob location"
  value       = var.datasync.azure_blob_location != null ? aws_datasync_location_azure_blob.this[0].arn : null
}

output "azure_blob_location_uri" {
  description = "URI of the DataSync Azure Blob location"
  value       = var.datasync.azure_blob_location != null ? aws_datasync_location_azure_blob.this[0].uri : null
}

#--------------------------------------------------------------------
# DataSync Task Outputs
#--------------------------------------------------------------------

output "datasync_task_arn" {
  description = "ARN of the DataSync task"
  value       = var.datasync.task != null ? aws_datasync_task.this[0].arn : null
}

output "datasync_task_status" {
  description = "Status of the DataSync task"
  value       = var.datasync.task != null ? aws_datasync_task.this[0].status : null
}

output "datasync_schedule_rule_arn" {
  description = "ARN of the CloudWatch Event Rule for DataSync scheduling"
  value       = var.datasync.task != null && var.datasync.task.schedule_expression != null ? aws_cloudwatch_event_rule.datasync_schedule[0].arn : null
}

output "datasync_events_role_arn" {
  description = "ARN of the IAM role used by CloudWatch Events for DataSync"
  value       = var.datasync.task != null && var.datasync.task.schedule_expression != null ? aws_iam_role.datasync_events_role[0].arn : null
}

#--------------------------------------------------------------------
# General Outputs
#--------------------------------------------------------------------

output "all_location_arns" {
  description = "List of all created DataSync location ARNs"
  value = compact([
    var.datasync.s3_location != null ? aws_datasync_location_s3.this[0].arn : null,
    var.datasync.efs_location != null ? aws_datasync_location_efs.this[0].arn : null,
    var.datasync.fsx_windows_location != null ? aws_datasync_location_fsx_windows_file_system.this[0].arn : null,
    var.datasync.fsx_lustre_location != null ? aws_datasync_location_fsx_lustre_file_system.this[0].arn : null,
    var.datasync.fsx_ontap_location != null ? aws_datasync_location_fsx_ontap_file_system.this[0].arn : null,
    var.datasync.fsx_openzfs_location != null ? aws_datasync_location_fsx_openzfs_file_system.this[0].arn : null,
    var.datasync.nfs_location != null ? aws_datasync_location_nfs.this[0].arn : null,
    var.datasync.smb_location != null ? aws_datasync_location_smb.this[0].arn : null,
    var.datasync.hdfs_location != null ? aws_datasync_location_hdfs.this[0].arn : null,
    var.datasync.object_storage_location != null ? aws_datasync_location_object_storage.this[0].arn : null,
    var.datasync.azure_blob_location != null ? aws_datasync_location_azure_blob.this[0].arn : null,
  ])
}

output "datasync_locations_count" {
  description = "Number of DataSync locations created"
  value = length(compact([
    var.datasync.s3_location != null ? "s3" : null,
    var.datasync.efs_location != null ? "efs" : null,
    var.datasync.fsx_windows_location != null ? "fsx_windows" : null,
    var.datasync.fsx_lustre_location != null ? "fsx_lustre" : null,
    var.datasync.fsx_ontap_location != null ? "fsx_ontap" : null,
    var.datasync.fsx_openzfs_location != null ? "fsx_openzfs" : null,
    var.datasync.nfs_location != null ? "nfs" : null,
    var.datasync.smb_location != null ? "smb" : null,
    var.datasync.hdfs_location != null ? "hdfs" : null,
    var.datasync.object_storage_location != null ? "object_storage" : null,
    var.datasync.azure_blob_location != null ? "azure_blob" : null,
  ]))
}

#--------------------------------------------------------------------
# CloudWatch Log Group Outputs
#--------------------------------------------------------------------

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for DataSync"
  value       = var.datasync.create_cloudwatch_log_group ? aws_cloudwatch_log_group.datasync[0].arn : null
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for DataSync"
  value       = var.datasync.create_cloudwatch_log_group ? aws_cloudwatch_log_group.datasync[0].name : null
}