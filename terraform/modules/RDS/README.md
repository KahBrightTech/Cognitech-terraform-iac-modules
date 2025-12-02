# RDS Module

This Terraform module creates an AWS RDS instance with automatic password generation and stores all credentials and connection details in AWS Secrets Manager.

## Features

- ✅ Creates RDS instance with configurable engine (MySQL, PostgreSQL, MariaDB, Oracle, SQL Server)
- ✅ Automatically generates a secure random password
- ✅ Stores all credentials and connection info in AWS Secrets Manager
- ✅ Supports encryption at rest with KMS
- ✅ Configurable backup and maintenance windows
- ✅ Optional read replica support
- ✅ Multi-AZ deployment support
- ✅ Performance Insights and Enhanced Monitoring
- ✅ CloudWatch Logs integration

## Usage

```hcl
module "rds" {
  source = "./modules/RDS"

  common = {
    global        = false
    tags = {
      Environment = "production"
      Project     = "my-app"
    }
    account_name  = "myaccount"
    region_prefix = "us-east-1"
  }

  rds_instance = {
    name                   = "myapp-db"
    engine                 = "postgres"
    engine_version         = "15.4"
    instance_class         = "db.t3.medium"
    allocated_storage      = 100
    max_allocated_storage  = 1000
    storage_type           = "gp3"
    storage_encrypted      = true
    kms_key_id             = "arn:aws:kms:us-east-1:123456789012:key/abc-123"
    
    database_name          = "myappdb"
    master_username        = "dbadmin"
    port                   = 5432
    
    subnet_ids             = ["subnet-12345", "subnet-67890"]
    vpc_security_group_ids = ["sg-12345"]
    publicly_accessible    = false
    
    multi_az               = true
    parameter_group_name   = "default.postgres15"
    
    backup_retention_period   = 7
    backup_window             = "03:00-04:00"
    maintenance_window        = "mon:04:00-mon:05:00"
    auto_minor_version_upgrade = true
    
    deletion_protection       = true
    skip_final_snapshot       = false
    copy_tags_to_snapshot     = true
    
    enabled_cloudwatch_logs_exports = ["postgresql"]
    monitoring_interval             = 60
    monitoring_role_arn             = "arn:aws:iam::123456789012:role/rds-monitoring-role"
    performance_insights_enabled    = true
    
    apply_immediately      = false
    
    # Secrets Manager configuration
    secrets_kms_key_id           = "arn:aws:kms:us-east-1:123456789012:key/def-456"
    secret_recovery_window_days  = 30
    
    # Optional read replica
    create_read_replica    = true
    replica_instance_class = "db.t3.small"
  }
}
```

## Secret Format

The module stores the following information in AWS Secrets Manager as JSON:

```json
{
  "username": "dbadmin",
  "password": "generated-secure-password",
  "engine": "postgres",
  "engine_version": "15.4",
  "host": "myaccount-myapp-db.abc123.us-east-1.rds.amazonaws.com",
  "endpoint": "myaccount-myapp-db.abc123.us-east-1.rds.amazonaws.com:5432",
  "port": 5432,
  "database_name": "myappdb",
  "instance_identifier": "myaccount-myapp-db",
  "instance_arn": "arn:aws:rds:us-east-1:123456789012:db:myaccount-myapp-db",
  "instance_id": "myaccount-myapp-db",
  "resource_id": "db-ABC123DEF456",
  "availability_zone": "us-east-1a",
  "multi_az": true,
  "storage_encrypted": true,
  "ca_cert_identifier": "rds-ca-2019"
}
```

## Retrieving Secrets

### Using AWS CLI

```bash
aws secretsmanager get-secret-value \
  --secret-id myaccount/myapp-db/rds-credentials \
  --query SecretString \
  --output text | jq -r .password
```

### Using Terraform Data Source

```hcl
data "aws_secretsmanager_secret_version" "rds_creds" {
  secret_id = module.rds.secret_id
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.rds_creds.secret_string)
}

# Use the credentials
resource "null_resource" "example" {
  provisioner "local-exec" {
    command = "psql -h ${local.db_creds.host} -U ${local.db_creds.username} -d ${local.db_creds.database_name}"
  }
}
```

## Engine Examples

### MySQL

```hcl
rds_instance = {
  engine         = "mysql"
  engine_version = "8.0.35"
  port           = 3306
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  # ... other settings
}
```

### PostgreSQL

```hcl
rds_instance = {
  engine         = "postgres"
  engine_version = "15.4"
  port           = 5432
  enabled_cloudwatch_logs_exports = ["postgresql"]
  # ... other settings
}
```

### MariaDB

```hcl
rds_instance = {
  engine         = "mariadb"
  engine_version = "10.11.6"
  port           = 3306
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  # ... other settings
}
```

### SQL Server

```hcl
rds_instance = {
  engine         = "sqlserver-ex"
  engine_version = "15.00.4335.1.v1"
  port           = 1433
  enabled_cloudwatch_logs_exports = ["error"]
  # ... other settings
}
```

### Oracle

```hcl
rds_instance = {
  engine         = "oracle-se2"
  engine_version = "19.0.0.0.ru-2023-10.rur-2023-10.r1"
  port           = 1521
  # ... other settings
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| common | Common variables used by all resources | object | n/a | yes |
| rds_instance | RDS instance configuration | object | null | no |

### RDS Instance Object

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the RDS instance | string | n/a | yes |
| engine | Database engine | string | n/a | yes |
| engine_version | Database engine version | string | n/a | yes |
| instance_class | Instance class | string | n/a | yes |
| allocated_storage | Initial storage in GB | number | n/a | yes |
| max_allocated_storage | Maximum storage for autoscaling | number | null | no |
| storage_type | Storage type | string | "gp3" | no |
| storage_encrypted | Enable storage encryption | bool | true | no |
| kms_key_id | KMS key for storage encryption | string | null | no |
| database_name | Initial database name | string | null | no |
| master_username | Master username | string | n/a | yes |
| port | Database port | number | null | no |
| subnet_ids | List of subnet IDs | list(string) | n/a | yes |
| vpc_security_group_ids | List of security group IDs | list(string) | n/a | yes |
| publicly_accessible | Make instance publicly accessible | bool | false | no |
| multi_az | Enable multi-AZ deployment | bool | false | no |
| backup_retention_period | Backup retention in days | number | 7 | no |
| deletion_protection | Enable deletion protection | bool | true | no |
| skip_final_snapshot | Skip final snapshot on deletion | bool | false | no |
| secrets_kms_key_id | KMS key for secrets encryption | string | null | no |
| secret_recovery_window_days | Secret recovery window | number | 30 | no |
| create_read_replica | Create a read replica | bool | false | no |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_id | The RDS instance ID |
| db_instance_arn | The ARN of the RDS instance |
| db_instance_endpoint | The connection endpoint |
| db_instance_address | The hostname of the RDS instance |
| db_instance_port | The database port |
| secret_arn | The ARN of the secret containing RDS credentials |
| secret_id | The ID of the secret |
| secret_name | The name of the secret |
| read_replica_endpoint | The connection endpoint of the read replica |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |
| random | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.0 |
| random | >= 3.0 |

## Notes

- The password is automatically generated and stored only in Secrets Manager
- Final snapshots are created by default (set `skip_final_snapshot = true` to disable)
- Deletion protection is enabled by default
- Storage is encrypted by default
- The module uses lifecycle rules to ignore password changes after initial creation
- Secret recovery window is 30 days by default (can be 7-30 days)

## License

This module is maintained by your organization.
