# S3 Private Bucket Encryption Configuration

This module now supports configurable encryption options for S3 buckets.

## Encryption Configuration

The encryption configuration is controlled through the `s3.encryption` object with the following options:

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `enabled` | `bool` | `true` | Whether to enable server-side encryption |
| `sse_algorithm` | `string` | `"AES256"` | Server-side encryption algorithm. Valid values: `"AES256"`, `"aws:kms"` |
| `kms_master_key_id` | `string` | `null` | KMS key ID for encryption (required when `sse_algorithm` is `"aws:kms"`) |
| `bucket_key_enabled` | `bool` | `false` | Whether to use S3 Bucket Keys for KMS encryption |

## Usage Examples

### Basic AES256 Encryption (Default)

```hcl
module "s3_bucket" {
  source = "./modules/S3-Private-bucket"
  
  common = {
    global        = false
    tags          = {}
    account_name  = "my-account"
    region_prefix = "us-east-1"
  }
  
  s3 = {
    name        = "my-bucket"
    description = "My private bucket with default encryption"
    # encryption uses default values:
    # enabled = true, sse_algorithm = "AES256"
  }
}
```

### KMS Encryption

```hcl
module "s3_bucket" {
  source = "./modules/S3-Private-bucket"
  
  common = {
    global        = false
    tags          = {}
    account_name  = "my-account"
    region_prefix = "us-east-1"
  }
  
  s3 = {
    name        = "my-bucket"
    description = "My private bucket with KMS encryption"
    encryption = {
      enabled            = true
      sse_algorithm      = "aws:kms"
      kms_master_key_id  = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
      bucket_key_enabled = true
    }
  }
}
```

### Disable Encryption

```hcl
module "s3_bucket" {
  source = "./modules/S3-Private-bucket"
  
  common = {
    global        = false
    tags          = {}
    account_name  = "my-account"
    region_prefix = "us-east-1"
  }
  
  s3 = {
    name        = "my-bucket"
    description = "My private bucket without encryption"
    encryption = {
      enabled = false
    }
  }
}
```

## Validation Rules

1. **Algorithm Validation**: The `sse_algorithm` must be either `"AES256"` or `"aws:kms"`.
2. **KMS Key Requirement**: When using `"aws:kms"` encryption, the `kms_master_key_id` must be provided.

## Benefits

- **AES256**: Server-side encryption with Amazon S3-managed keys (SSE-S3)
- **aws:kms**: Server-side encryption with AWS KMS keys (SSE-KMS)
  - Provides additional access controls
  - Audit trail through CloudTrail
  - Can use customer-managed keys
  - S3 Bucket Keys can reduce KMS costs

## Outputs

The module now includes an `encryption` output that provides information about the current encryption configuration:

```hcl
output "encryption" {
  value = {
    enabled            = true/false
    sse_algorithm      = "AES256" or "aws:kms" or null
    kms_master_key_id  = "key-id" or null
    bucket_key_enabled = true/false
  }
}
```
