# ECR (Elastic Container Registry) Module

This Terraform module creates and manages AWS Elastic Container Registry (ECR) repositories with comprehensive configuration options.

## Features

- ECR repository creation with customizable naming
- Image tag mutability configuration (MUTABLE/IMMUTABLE)
- Automatic image scanning on push
- Encryption configuration (AES256 or KMS)
- Lifecycle policies for automated image cleanup
- Repository policies for access control
- Cross-region replication support
- Force delete option for easier cleanup

## Usage

### Basic Example

```hcl
module "ecr" {
  source = "../modules/ECR"

  common = {
    global        = false
    account_name  = "myapp"
    region_prefix = "use1"
    tags = {
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }

  ecr = {
    name                 = "web-application"
    image_tag_mutability = "IMMUTABLE"
    scan_on_push         = true
    encryption_type      = "AES256"
    force_delete         = false
  }
}
```

### Advanced Example with Lifecycle Policy

```hcl
module "ecr_with_lifecycle" {
  source = "../modules/ECR"

  common = {
    global        = false
    account_name  = "myapp"
    region_prefix = "use1"
    tags = {
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }

  ecr = {
    name                 = "backend-api"
    image_tag_mutability = "MUTABLE"
    scan_on_push         = true
    encryption_type      = "AES256"
    force_delete         = false
    
    lifecycle_policy = jsonencode({
      rules = [
        {
          rulePriority = 1
          description  = "Keep last 10 images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["v"]
            countType     = "imageCountMoreThan"
            countNumber   = 10
          }
          action = {
            type = "expire"
          }
        },
        {
          rulePriority = 2
          description  = "Remove untagged images after 7 days"
          selection = {
            tagStatus   = "untagged"
            countType   = "sinceImagePushed"
            countUnit   = "days"
            countNumber = 7
          }
          action = {
            type = "expire"
          }
        }
      ]
    })
  }
}
```

### Example with KMS Encryption

```hcl
module "ecr_with_kms" {
  source = "../modules/ECR"

  common = {
    global        = false
    account_name  = "myapp"
    region_prefix = "use1"
    tags = {
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }

  ecr = {
    name                 = "secure-app"
    image_tag_mutability = "IMMUTABLE"
    scan_on_push         = true
    encryption_type      = "KMS"
    kms_key_arn          = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    force_delete         = false
  }
}
```

### Example with Cross-Account Repository Policy

```hcl
module "ecr_with_policy" {
  source = "../modules/ECR"

  common = {
    global        = false
    account_name  = "myapp"
    region_prefix = "use1"
    tags = {
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }

  ecr = {
    name                 = "shared-images"
    image_tag_mutability = "IMMUTABLE"
    scan_on_push         = true
    encryption_type      = "AES256"
    
    repository_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "AllowCrossAccountPull"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::987654321098:root"
          }
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability"
          ]
        }
      ]
    })
  }
}
```

### Example with Replication Configuration

```hcl
module "ecr_with_replication" {
  source = "../modules/ECR"

  common = {
    global        = false
    account_name  = "myapp"
    region_prefix = "use1"
    tags = {
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }

  ecr = {
    name                 = "replicated-app"
    image_tag_mutability = "IMMUTABLE"
    scan_on_push         = true
    encryption_type      = "AES256"
    
    replication_configuration = {
      rules = [
        {
          destinations = [
            {
              region      = "us-west-2"
              registry_id = "123456789012"
            }
          ]
          repository_filter = {
            filter      = "prod-*"
            filter_type = "PREFIX_MATCH"
          }
        }
      ]
    }
  }
}
```

## Variables

### common

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| global | Whether this is a global resource | `bool` | yes |
| tags | Tags to apply to all resources | `map(string)` | yes |
| account_name | Account name for resource naming | `string` | yes |
| region_prefix | Region prefix for resource naming | `string` | yes |
| account_name_abr | Account name abbreviation | `string` | no |

### ecr

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name of the ECR repository | `string` | - | yes |
| image_tag_mutability | Tag mutability setting (MUTABLE or IMMUTABLE) | `string` | `"MUTABLE"` | no |
| scan_on_push | Enable scanning images on push | `bool` | `true` | no |
| encryption_type | Encryption type (AES256 or KMS) | `string` | `"AES256"` | no |
| kms_key_arn | KMS key ARN (required if encryption_type is KMS) | `string` | `null` | no |
| force_delete | Allow deletion of non-empty repository | `bool` | `false` | no |
| lifecycle_policy | JSON encoded lifecycle policy | `string` | `null` | no |
| repository_policy | JSON encoded repository policy | `string` | `null` | no |
| replication_configuration | Replication configuration object | `object` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_arn | The ARN of the ECR repository |
| repository_name | The name of the ECR repository |
| repository_registry_id | The registry ID where the repository was created |
| repository_url | The URL of the repository |
| repository_id | The ID of the ECR repository |
| lifecycle_policy_text | The lifecycle policy text, if configured |
| repository_policy_text | The repository policy text, if configured |

## Notes

- When using KMS encryption, ensure the KMS key has the appropriate permissions
- Image tag mutability cannot be changed after repository creation without recreating the repository
- Use IMMUTABLE tags for production environments to ensure image integrity
- Lifecycle policies help manage storage costs by automatically removing old or untagged images
- Repository policies enable cross-account access to your container images
- Force delete should be used with caution as it will delete the repository even if it contains images

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.5 |
| aws | >= 4.37.0 |
