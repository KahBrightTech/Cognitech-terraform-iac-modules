# Terragrunt configuration for AWS RDS MySQL Free Tier
terraform {
  source = "."
}

# Include root terragrunt configuration if you have one
# include "root" {
#   path = find_in_parent_folders()
# }

inputs = {
  common = {
    global        = false
    account_name  = "myaccount"       # Change to your account name
    region_prefix = "use1"             # Change to your region prefix (e.g., use1 for us-east-1)
    tags = {
      Environment = "dev"
      ManagedBy   = "Terragrunt"
      Project     = "free-tier-rds"
    }
  }

  rds_instance = {
    name           = "mysql-free-tier"
    engine         = "mysql"
    engine_version = "8.0.35"           # MySQL version compatible with free tier
    instance_class = "db.t3.micro"      # Free tier eligible instance class (750 hours/month)

    # Storage configuration (20GB max for free tier)
    allocated_storage     = 20          # Free tier includes 20GB of storage
    max_allocated_storage = 20          # Prevent autoscaling beyond free tier
    storage_type          = "gp2"       # General Purpose SSD (gp2 or gp3 are free tier eligible)
    storage_encrypted     = false       # Set to false to avoid KMS charges (optional, set to true if you need encryption)

    # Database configuration
    database_name   = "mydb"            # Initial database name
    master_username = null              # Will auto-generate a username
    port            = 3306              # Default MySQL port

    # Network configuration - REPLACE WITH YOUR VALUES
    subnet_ids             = ["subnet-xxxxx", "subnet-yyyyy"]  # Your private subnet IDs
    vpc_security_group_ids = ["sg-xxxxx"]                      # Your security group ID
    publicly_accessible    = false                              # Keep false for security

    # Availability configuration
    multi_az          = false           # Free tier doesn't support Multi-AZ
    availability_zone = null            # Let AWS choose

    # Backup configuration
    backup_retention_period = 7         # Days to retain backups (free tier includes automated backups)
    backup_window           = "03:00-04:00"     # UTC time
    maintenance_window      = "sun:04:00-sun:05:00"  # UTC time
    auto_minor_version_upgrade = true

    # Deletion protection
    deletion_protection = false         # Set to true for production
    skip_final_snapshot = true          # Set to false for production
    copy_tags_to_snapshot = true

    # Monitoring (keep minimal to avoid charges)
    enabled_cloudwatch_logs_exports = []  # Leave empty to avoid CloudWatch charges
    monitoring_interval              = 0  # Disable enhanced monitoring (would incur charges)
    performance_insights_enabled     = false  # Disable to avoid charges

    # Apply changes immediately (use with caution)
    apply_immediately = false

    # Secrets Manager configuration
    secret_recovery_window_days = 7

    # No read replica for free tier
    create_read_replica = false
  }
}

# Dependency configuration (if needed)
# dependencies {
#   paths = ["../vpc", "../security-groups"]
# }

# Remote state configuration example
# remote_state {
#   backend = "s3"
#   config = {
#     bucket         = "your-terraform-state-bucket"
#     key            = "rds/mysql-free-tier/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock"
#   }
# }
