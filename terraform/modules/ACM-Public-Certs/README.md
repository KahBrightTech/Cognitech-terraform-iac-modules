# ACM Public Certificates Module

This Terraform module provisions AWS Certificate Manager (ACM) public certificates with DNS validation using Route 53.

## Features

- Creates ACM certificates for public domains
- Automatic DNS validation using Route 53
- Certificate validation with Route 53 records
- Supports custom tagging

## Prerequisites

- AWS Route 53 hosted zone for the domain
- Appropriate IAM permissions for ACM and Route 53
- Domain ownership verification

## Usage with Terragrunt

### Basic Configuration

Create a `terragrunt.hcl` file in your formation directory:

```hcl
# terragrunt.hcl
terraform {
  source = "git::https://github.com/KahBrightTech/Cognitech-terraform-iac-modules.git//terraform/modules/ACM-Public-Certs?ref=main"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  certificate = {
    domain_name       = "example.com"
    validation_method = "DNS"
    name              = "example-cert"
  }
  
  common = {
    account_name   = "production"
    region_prefix  = "us-east-1"
    tags = {
      Environment = "production"
      Project     = "my-project"
      Owner       = "infrastructure-team"
    }
  }
}
```

### Advanced Configuration with Subject Alternative Names

```hcl
# terragrunt.hcl
terraform {
  source = "git::https://github.com/KahBrightTech/Cognitech-terraform-iac-modules.git//terraform/modules/ACM-Public-Certs?ref=main"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  certificate = {
    domain_name       = "example.com"
    validation_method = "DNS"
    name              = "wildcard-cert"
    subject_alternative_names = [
      "*.example.com",
      "api.example.com",
      "www.example.com"
    ]
  }
  
  common = {
    account_name   = "production"
    region_prefix  = "us-east-1"
    tags = {
      Environment = "production"
      Project     = "my-project"
      Owner       = "infrastructure-team"
      CostCenter  = "engineering"
    }
  }
}
```

### Multi-Environment Setup

For different environments, create separate directories:

```
formations/
├── dev/
│   ├── certificates/
│   │   └── terragrunt.hcl
├── staging/
│   ├── certificates/
│   │   └── terragrunt.hcl
└── prod/
    ├── certificates/
    └── terragrunt.hcl
```

**Development Environment** (`dev/certificates/terragrunt.hcl`):
```hcl
terraform {
  source = "git::https://github.com/KahBrightTech/Cognitech-terraform-iac-modules.git//terraform/modules/ACM-Public-Certs?ref=main"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  certificate = {
    domain_name       = "dev.example.com"
    validation_method = "DNS"
    name              = "dev-cert"
  }
  
  common = {
    account_name   = "development"
    region_prefix  = "us-west-2"
    tags = {
      Environment = "development"
      Project     = "my-project"
      Owner       = "dev-team"
    }
  }
}
```

**Production Environment** (`prod/certificates/terragrunt.hcl`):
```hcl
terraform {
  source = "git::https://github.com/KahBrightTech/Cognitech-terraform-iac-modules.git//terraform/modules/ACM-Public-Certs?ref=main"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  certificate = {
    domain_name       = "example.com"
    validation_method = "DNS"
    name              = "prod-cert"
  }
  
  common = {
    account_name   = "production"
    region_prefix  = "us-east-1"
    tags = {
      Environment = "production"
      Project     = "my-project"
      Owner       = "infrastructure-team"
      Backup      = "required"
    }
  }
}
```

### Using with Dependencies

If you need to reference other Terragrunt modules, use dependencies:

```hcl
# terragrunt.hcl
terraform {
  source = "git::https://github.com/KahBrightTech/Cognitech-terraform-iac-modules.git//terraform/modules/ACM-Public-Certs?ref=main"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "route53" {
  config_path = "../route53-hosted-zone"
  mock_outputs = {
    zone_id = "Z1234567890ABC"
  }
}

inputs = {
  certificate = {
    domain_name       = "example.com"
    validation_method = "DNS"
    name              = "example-cert"
  }
  
  common = {
    account_name   = "production"
    region_prefix  = "us-east-1"
    tags = {
      Environment = "production"
      Project     = "my-project"
      Owner       = "infrastructure-team"
    }
  }
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| certificate | Certificate configuration object | `object` | n/a | yes |
| certificate.domain_name | Domain name for the certificate | `string` | n/a | yes |
| certificate.validation_method | Validation method (DNS or EMAIL) | `string` | n/a | yes |
| certificate.name | Name identifier for the certificate | `string` | n/a | yes |
| certificate.subject_alternative_names | Additional domain names | `list(string)` | `[]` | no |
| common | Common configuration object | `object` | n/a | yes |
| common.account_name | Account name for resource naming | `string` | n/a | yes |
| common.region_prefix | Region prefix for resource naming | `string` | n/a | yes |
| common.tags | Common tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| certificate_arn | ARN of the ACM certificate |
| certificate_domain_name | Domain name of the certificate |
| certificate_status | Status of the certificate |
| validation_record_fqdns | List of FQDNs for validation records |

## Deployment Commands

### Initialize and Plan
```bash
# Navigate to your formation directory
cd formations/prod/certificates

# Initialize Terragrunt
terragrunt init

# Plan the deployment
terragrunt plan
```

### Apply Changes
```bash
# Apply the configuration
terragrunt apply

# Apply with auto-approval (use with caution)
terragrunt apply -auto-approve
```

### Destroy Resources
```bash
# Destroy the certificate
terragrunt destroy

# Destroy with auto-approval (use with caution)
terragrunt destroy -auto-approve
```

## Important Notes

1. **Domain Ownership**: Ensure you own the domain and have access to the Route 53 hosted zone
2. **DNS Propagation**: DNS validation may take several minutes to complete
3. **Certificate Limits**: AWS has limits on the number of certificates per account
4. **Regional Deployment**: For CloudFront, certificates must be deployed in `us-east-1`
5. **Auto-Renewal**: ACM certificates are automatically renewed by AWS

## Troubleshooting

### Common Issues

1. **Route 53 Zone Not Found**
   - Ensure the hosted zone exists for the domain
   - Check that the zone is public (not private)

2. **Permission Errors**
   - Verify IAM permissions for ACM and Route 53
   - Ensure the role has necessary permissions

3. **Validation Timeout**
   - Check DNS propagation
   - Verify Route 53 records are created correctly

### Debug Commands

```bash
# Check Terragrunt configuration
terragrunt validate

# View current state
terragrunt show

# Debug with verbose output
terragrunt plan -var-file=terraform.tfvars --terragrunt-log-level debug
```

## Example Integration

Here's how to reference the certificate in other modules:

```hcl
# In another terragrunt.hcl file
dependency "certificate" {
  config_path = "../certificates"
  mock_outputs = {
    certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
  }
}

inputs = {
  certificate_arn = dependency.certificate.outputs.certificate_arn
  # ... other inputs
}
```

This module provides a secure and automated way to manage SSL/TLS certificates for your applications using AWS Certificate Manager and Route 53.
