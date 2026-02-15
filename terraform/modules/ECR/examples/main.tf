terraform {
  required_version = ">= 1.5.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.37.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

#--------------------------------------------------------------------
# Basic ECR Repository
#--------------------------------------------------------------------

module "ecr_basic" {
  source = "../../modules/ECR"

  common = {
    global        = false
    account_name  = "cognitech"
    region_prefix = "use1"
    tags = {
      Environment = "development"
      ManagedBy   = "Terraform"
      Project     = "example"
    }
  }

  ecr = {
    name                 = "basic-app"
    image_tag_mutability = "MUTABLE"
    scan_on_push         = true
    encryption_type      = "AES256"
    force_delete         = true # Set to true for testing, false for production
  }
}

#--------------------------------------------------------------------
# ECR with Immutable Tags and Lifecycle Policy
#--------------------------------------------------------------------

module "ecr_production" {
  source = "../../modules/ECR"

  common = {
    global        = false
    account_name  = "cognitech"
    region_prefix = "use1"
    tags = {
      Environment = "production"
      ManagedBy   = "Terraform"
      Project     = "example"
    }
  }

  ecr = {
    name                 = "production-app"
    image_tag_mutability = "IMMUTABLE"
    scan_on_push         = true
    encryption_type      = "AES256"
    force_delete         = false

    # Lifecycle policy to manage image retention
    lifecycle_policy = jsonencode({
      rules = [
        {
          rulePriority = 1
          description  = "Keep last 30 production images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["prod-", "v"]
            countType     = "imageCountMoreThan"
            countNumber   = 30
          }
          action = {
            type = "expire"
          }
        },
        {
          rulePriority = 2
          description  = "Keep last 10 staging images"
          selection = {
            tagStatus     = "tagged"
            tagPrefixList = ["staging-", "stage-"]
            countType     = "imageCountMoreThan"
            countNumber   = 10
          }
          action = {
            type = "expire"
          }
        },
        {
          rulePriority = 3
          description  = "Remove untagged images older than 7 days"
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

#--------------------------------------------------------------------
# ECR with Cross-Account Access Policy
#--------------------------------------------------------------------

module "ecr_shared" {
  source = "../../modules/ECR"

  common = {
    global        = false
    account_name  = "cognitech"
    region_prefix = "use1"
    tags = {
      Environment = "shared"
      ManagedBy   = "Terraform"
      Project     = "example"
    }
  }

  ecr = {
    name                 = "shared-images"
    image_tag_mutability = "IMMUTABLE"
    scan_on_push         = true
    encryption_type      = "AES256"
    force_delete         = false

    # Repository policy for cross-account access
    repository_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "AllowPushPull"
          Effect = "Allow"
          Principal = {
            AWS = [
              "arn:aws:iam::123456789012:root", # Replace with your account ID
              "arn:aws:iam::123456789012:role/ECRAccessRole"
            ]
          }
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload"
          ]
        },
        {
          Sid    = "AllowCrossAccountPull"
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::987654321098:root" # Replace with other account ID
          }
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability"
          ]
        }
      ]
    })

    lifecycle_policy = jsonencode({
      rules = [
        {
          rulePriority = 1
          description  = "Keep last 50 images"
          selection = {
            tagStatus   = "any"
            countType   = "imageCountMoreThan"
            countNumber = 50
          }
          action = {
            type = "expire"
          }
        }
      ]
    })
  }
}

#--------------------------------------------------------------------
# Outputs
#--------------------------------------------------------------------

output "basic_repository_url" {
  description = "URL of the basic ECR repository"
  value       = module.ecr_basic.repository_url
}

output "production_repository_url" {
  description = "URL of the production ECR repository"
  value       = module.ecr_production.repository_url
}

output "shared_repository_url" {
  description = "URL of the shared ECR repository"
  value       = module.ecr_shared.repository_url
}

output "basic_repository_arn" {
  description = "ARN of the basic ECR repository"
  value       = module.ecr_basic.repository_arn
}

output "production_repository_arn" {
  description = "ARN of the production ECR repository"
  value       = module.ecr_production.repository_arn
}

output "shared_repository_arn" {
  description = "ARN of the shared ECR repository"
  value       = module.ecr_shared.repository_arn
}
