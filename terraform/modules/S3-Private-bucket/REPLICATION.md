# S3 Bucket Replication Configuration Documentation

## Overview

This module supports comprehensive S3 bucket replication configuration with cross-region replication (CRR) and same-region replication (SRR) capabilities. The replication feature allows automatic copying of objects from a source bucket to one or more destination buckets.

## Architecture

```
┌─────────────────┐    Replication     ┌─────────────────┐
│  Source Bucket  │ ──────────────────► │ Destination     │
│  (us-east-1)    │                    │ Bucket          │
│                 │                    │ (us-west-2)     │
│ ┌─────────────┐ │                    │ ┌─────────────┐ │
│ │   Objects   │ │                    │ │  Replicas   │ │
│ │ - Encrypted │ │                    │ │ - Encrypted │ │
│ │ - Filtered  │ │                    │ │ - Monitored │ │
│ └─────────────┘ │                    │ └─────────────┘ │
└─────────────────┘                    └─────────────────┘
```

## Configuration Structure

### Basic Replication Configuration

```hcl
variable "s3" {
  type = object({
    # ... other s3 configurations
    replication = optional(object({
      role_arn = string
      rules = list(object({
        status                    = string
        delete_marker_replication = optional(bool, false)
        prefix                    = optional(string, "")
        filter = optional(object({
          prefix = string
        }))
        destination = object({
          bucket_arn                   = string
          storage_class               = optional(string, "STANDARD")
          access_control_translation = optional(object({
            owner = string
          }))
          encryption_configuration = optional(object({
            replica_kms_key_id = string
          }))
          replication_time = optional(object({
            minutes = number
          }))
          replica_modification = optional(bool, true)
        })
      }))
    }))
  })
}
```

## Configuration Components

### 1. Replication Role (`role_arn`)

**Purpose**: IAM role that S3 assumes to replicate objects
**Required**: Yes
**Format**: ARN of IAM role

```hcl
role_arn = "arn:aws:iam::123456789012:role/replication-role"
```

**Required IAM Policy for Replication Role**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging"
      ],
      "Resource": "arn:aws:s3:::source-bucket/*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Resource": "arn:aws:s3:::destination-bucket/*"
    }
  ]
}
```

### 2. Replication Rules

#### Rule Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `status` | string | Yes | - | `"Enabled"` or `"Disabled"` |
| `delete_marker_replication` | bool | No | `false` | Replicate delete markers |
| `prefix` | string | No | `""` | Object key prefix filter |
| `filter` | object | No | - | Advanced filtering options |

#### Filter Configuration

```hcl
filter = {
  prefix = "documents/"  # Only replicate objects with this prefix
}
```

### 3. Destination Configuration

#### Basic Destination Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `bucket_arn` | string | Yes | - | ARN of destination bucket |
| `storage_class` | string | No | `"STANDARD"` | Storage class for replicas |

**Available Storage Classes**:
- `STANDARD`
- `STANDARD_IA`
- `ONEZONE_IA`
- `REDUCED_REDUNDANCY`
- `GLACIER`
- `DEEP_ARCHIVE`
- `INTELLIGENT_TIERING`

#### Access Control Translation

```hcl
access_control_translation = {
  owner = "Destination"  # Change object ownership to destination bucket owner
}
```

#### Encryption Configuration

**Purpose**: Encrypt replicated objects in destination bucket
**Requirement**: When specified, automatically enables `source_selection_criteria`

```hcl
encryption_configuration = {
  replica_kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
}
```

**⚠️ Important**: When `encryption_configuration` is present, the module automatically adds:
```hcl
source_selection_criteria = {
  sse_kms_encrypted_objects = {
    status = "Enabled"
  }
}
```

#### Replication Time Control (RTC)

**Purpose**: Replicate objects within specified time frame

```hcl
replication_time = {
  minutes = 15  # Replicate within 15 minutes
}
```

**Features**:
- Provides predictable replication time
- Enables replication metrics
- Default: 15 minutes if not specified

#### Replication Metrics

**Purpose**: Enable CloudWatch metrics for replication

```hcl
replica_modification = true  # Enable replication metrics
```

**Available Metrics**:
- Replication latency
- Bytes pending replication
- Operations pending replication

### 4. Delete Marker Replication

```hcl
delete_marker_replication = true  # Replicate delete markers
```

**When Enabled**:
- Delete markers are replicated to destination
- Maintains consistency between source and destination
- Useful for maintaining delete operations across regions

### 5. Source Selection Criteria (Automatic)

**⚠️ Auto-Generated**: This block is automatically created when `encryption_configuration` is present.

**Purpose**: Determines which source objects to replicate based on encryption status

```hcl
# Automatically generated when encryption_configuration exists
source_selection_criteria = {
  sse_kms_encrypted_objects = {
    status = "Enabled"  # Only replicate SSE-KMS encrypted objects
  }
}
```

## Usage Examples

### Example 1: Basic Cross-Region Replication

```hcl
module "s3_bucket" {
  source = "./modules/S3-Private-bucket"
  
  common = {
    account_name  = "mycompany"
    region_prefix = "use1"
    tags = {
      Environment = "production"
      Team        = "platform"
    }
  }
  
  s3 = {
    name = "application-data"
    replication = {
      role_arn = "arn:aws:iam::123456789012:role/s3-replication-role"
      rules = [
        {
          status = "Enabled"
          prefix = "important/"
          destination = {
            bucket_arn    = "arn:aws:s3:::mycompany-usw2-application-data-replica"
            storage_class = "STANDARD_IA"
          }
        }
      ]
    }
  }
}
```

### Example 2: Encrypted Replication with RTC

```hcl
s3 = {
  name = "secure-documents"
  replication = {
    role_arn = "arn:aws:iam::123456789012:role/s3-replication-role"
    rules = [
      {
        status                    = "Enabled"
        delete_marker_replication = true
        destination = {
          bucket_arn    = "arn:aws:s3:::mycompany-usw2-secure-documents"
          storage_class = "STANDARD"
          encryption_configuration = {
            replica_kms_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
          }
          replication_time = {
            minutes = 15
          }
          replica_modification = true
        }
      }
    ]
  }
}
```

### Example 3: Multi-Rule Replication

```hcl
s3 = {
  name = "multi-tier-data"
  replication = {
    role_arn = "arn:aws:iam::123456789012:role/s3-replication-role"
    rules = [
      {
        status = "Enabled"
        prefix = "hot-data/"
        destination = {
          bucket_arn    = "arn:aws:s3:::hot-data-replica"
          storage_class = "STANDARD"
          replication_time = {
            minutes = 5
          }
        }
      },
      {
        status = "Enabled"
        prefix = "warm-data/"
        destination = {
          bucket_arn    = "arn:aws:s3:::warm-data-replica"
          storage_class = "STANDARD_IA"
        }
      },
      {
        status = "Enabled"
        prefix = "cold-data/"
        destination = {
          bucket_arn    = "arn:aws:s3:::cold-data-replica"
          storage_class = "GLACIER"
        }
      }
    ]
  }
}
```

## Best Practices

### 1. IAM Role Configuration

✅ **Do**:
- Use dedicated IAM roles for replication
- Follow principle of least privilege
- Include KMS permissions for encrypted replication

❌ **Don't**:
- Use overly broad IAM permissions
- Share replication roles across unrelated buckets

### 2. Encryption Strategy

✅ **Do**:
- Use separate KMS keys for different regions
- Plan key rotation strategy
- Test cross-region key access

❌ **Don't**:
- Use the same KMS key across regions
- Forget to grant replication role access to KMS keys

### 3. Monitoring and Alerting

✅ **Do**:
- Enable replication metrics
- Set up CloudWatch alarms for replication failures
- Monitor replication time if RTC is enabled

❌ **Don't**:
- Deploy without monitoring
- Ignore replication lag alerts

### 4. Cost Optimization

✅ **Do**:
- Use appropriate storage classes for replicas
- Consider lifecycle policies for replicated data
- Use prefix filtering to limit replication scope

❌ **Don't**:
- Replicate unnecessary data
- Use STANDARD storage for all replicas

## Troubleshooting

### Common Issues

1. **Replication Role Permissions**
   ```
   Error: Access Denied when replicating objects
   Solution: Verify IAM role has required S3 and KMS permissions
   ```

2. **KMS Key Access**
   ```
   Error: Cannot access KMS key for encryption
   Solution: Grant replication role access to destination region KMS key
   ```

3. **Source Selection Criteria Missing**
   ```
   Error: SseKmsEncryptedObjects must be specified if EncryptionConfiguration is present
   Solution: This is automatically handled by the module
   ```

4. **Bucket Versioning**
   ```
   Error: Source bucket must have versioning enabled
   Solution: Ensure enable_versioning = true in bucket configuration
   ```

### Monitoring Queries

**CloudWatch Logs Query for Replication Failures**:
```
fields @timestamp, @message
| filter @message like /replication/
| filter @message like /failed/
| sort @timestamp desc
```

**CloudWatch Metrics to Monitor**:
- `AWS/S3/ReplicationLatency`
- `AWS/S3/BytesPendingReplication`
- `AWS/S3/OperationsPendingReplication`

## References

- [AWS S3 Replication Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)
- [Terraform aws_s3_bucket_replication_configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration)
- [AWS S3 Cross-Region Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/crr.html)
- [AWS S3 Same-Region Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/srr.html)
