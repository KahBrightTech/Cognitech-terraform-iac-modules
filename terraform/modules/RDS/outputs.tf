#--------------------------------------------------------------------
# RDS Instance outputs
#--------------------------------------------------------------------
output "db_instance_id" {
  description = "The RDS instance ID"
  value       = try(aws_db_instance.instance[0].id, null)
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = try(aws_db_instance.instance[0].arn, null)
}

output "db_instance_identifier" {
  description = "The identifier of the RDS instance"
  value       = try(aws_db_instance.instance[0].identifier, null)
}

output "db_instance_resource_id" {
  description = "The resource ID of the RDS instance"
  value       = try(aws_db_instance.instance[0].resource_id, null)
}

output "db_instance_endpoint" {
  description = "The connection endpoint in address:port format"
  value       = try(aws_db_instance.instance[0].endpoint, null)
}

output "db_instance_address" {
  description = "The hostname of the RDS instance"
  value       = try(aws_db_instance.instance[0].address, null)
}

output "db_instance_port" {
  description = "The database port"
  value       = try(aws_db_instance.instance[0].port, null)
}

output "db_instance_name" {
  description = "The database name"
  value       = try(aws_db_instance.instance[0].db_name, null)
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = try(aws_db_instance.instance[0].username, null)
  sensitive   = true
}

output "db_instance_engine" {
  description = "The database engine"
  value       = try(aws_db_instance.instance[0].engine, null)
}

output "db_instance_engine_version" {
  description = "The running version of the database"
  value       = try(aws_db_instance.instance[0].engine_version_actual, null)
}

output "db_instance_availability_zone" {
  description = "The availability zone of the instance"
  value       = try(aws_db_instance.instance[0].availability_zone, null)
}

output "db_instance_multi_az" {
  description = "If the RDS instance is multi-AZ enabled"
  value       = try(aws_db_instance.instance[0].multi_az, null)
}

output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = try(aws_db_subnet_group.group[0].id, null)
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = try(aws_db_subnet_group.group[0].arn, null)
}

#--------------------------------------------------------------------
# Parameter Group outputs
#--------------------------------------------------------------------
output "db_parameter_group_id" {
  description = "The db parameter group name"
  value       = try(aws_db_parameter_group.parameter_group[0].id, null)
}

output "db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = try(aws_db_parameter_group.parameter_group[0].arn, null)
}

#--------------------------------------------------------------------
# Secrets Manager outputs
#--------------------------------------------------------------------
output "secret_arn" {
  description = "The ARN of the secret containing RDS credentials"
  value       = try(aws_secretsmanager_secret.rds_credentials[0].arn, null)
}

output "secret_id" {
  description = "The ID of the secret containing RDS credentials"
  value       = try(aws_secretsmanager_secret.rds_credentials[0].id, null)
}

output "secret_name" {
  description = "The name of the secret containing RDS credentials"
  value       = try(aws_secretsmanager_secret.rds_credentials[0].name, null)
}

output "secret_version_id" {
  description = "The version ID of the secret"
  value       = try(aws_secretsmanager_secret_version.rds_credentials[0].version_id, null)
}

#--------------------------------------------------------------------
# Read Replica outputs
#--------------------------------------------------------------------
output "read_replica_id" {
  description = "The RDS read replica instance ID"
  value       = try(aws_db_instance.read_replica[0].id, null)
}

output "read_replica_arn" {
  description = "The ARN of the RDS read replica instance"
  value       = try(aws_db_instance.read_replica[0].arn, null)
}

output "read_replica_endpoint" {
  description = "The connection endpoint of the read replica"
  value       = try(aws_db_instance.read_replica[0].endpoint, null)
}

output "read_replica_address" {
  description = "The hostname of the RDS read replica instance"
  value       = try(aws_db_instance.read_replica[0].address, null)
}
