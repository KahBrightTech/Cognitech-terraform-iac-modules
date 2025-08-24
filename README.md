# Cognitech Terraform Infrastructure as Code (IaC) Modules

A comprehensive collection of reusable Terraform modules and CloudFormation templates designed for enterprise-grade AWS infrastructure deployment with multi-region support and organizational best practices.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [CloudFormation Templates](#cloudformation-templates)
- [Terraform Modules](#terraform-modules)
- [Security & Compliance](#security--compliance)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Overview

This repository provides a standardized approach to AWS infrastructure deployment using Infrastructure as Code principles. It includes:

- **Multi-region KMS key management** for Terraform state encryption
- **Secure Terraform backend configuration** with S3 and DynamoDB
- **GitHub Actions CI/CD integration** using OIDC authentication
- **Reusable Terraform modules** for common AWS services
- **Enterprise security controls** and organizational policies

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Organization                         │
├─────────────────────────────────────────────────────────────┤
│  Primary Region (us-east-1)    │  Secondary Region (us-west-2) │
│  ├── KMS Key                   │  ├── KMS Key                  │
│  ├── S3 State Bucket          │  ├── S3 Backup Bucket         │
│  ├── DynamoDB Lock Table      │  └── Disaster Recovery        │
│  └── GitHub OIDC Provider     │                               │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Core Requirements

Before deploying any infrastructure components, ensure the following foundational requirements are met:

#### 1. AWS Organization Setup
- **AWS Organization**: Your AWS account must be part of an AWS Organization
- **Organization ID**: Must be configured properly for cross-account access and security policies
- **Cross-account roles**: Proper delegation between management and member accounts

#### 2. Domain and DNS Infrastructure
- **Public Domain**: A registered public domain is required for SSL certificate validation, API endpoints, and DNS resolution
- **Route 53 Hosted Zone**: Must be configured for your public domain to enable:
  - DNS management and resolution
  - SSL certificate validation via DNS
  - Cross-region DNS failover configurations
  - Environment-specific subdomain management

> **⚠️ Critical**: Without a public domain and hosted zone, SSL validation and DNS-dependent features will not function in production environments.

#### 3. Identity and Access Management
Configure the following permission sets in **AWS Identity Center (SSO)**:

##### Admin Role
- Full administrative access for infrastructure deployment
- Cross-region management capabilities
- CloudFormation and Terraform execution permissions

##### NetworkAdministrator Role
- VPC, subnet, and routing management
- Security group and NACL configuration
- DNS and certificate management
- Cross-region networking setup

> **🔄 Role Propagation Required**: Both the **Admin** and **NetworkAdministrator** roles must be propagated to all AWS accounts within your organization. This ensures consistent permissions across:
> - Management account and all member accounts
> - Development, staging, and production environments
> - Cross-account resource access and deployment capabilities
> - Centralized identity management through AWS Identity Center

#### 4. Development Environment
- **Terraform CLI**: Version 1.0+ installed and configured
- **AWS CLI**: Version 2.0+ with appropriate credentials
- **Git**: For version control and CI/CD integration
- **Backend State Management**: S3 bucket with KMS encryption (deployed via templates)

#### 5. Regional Configuration
- **Primary Region**: Typically `us-east-1` for global services
- **Secondary Region**: For disaster recovery and backup (e.g., `us-west-2`)
- **Service Availability**: Verify all required AWS services are available in target regions
- **Service Limits**: Review and request limit increases if necessary

### Optional Components

#### Ansible Tower Integration
For advanced automation and configuration management:
- **Account Setup**: Create account at [Red Hat Developer Portal](https://developers.redhat.com/products/ansible/download)
- **Version**: Download Ansible Tower 2.4 (recommended for compatibility)
- **Storage**: Upload installation package to designated S3 bucket for deployment

## Getting Started

### Quick Start Guide

1. **Clone the Repository**
   ```bash
   git clone https://github.com/KahBrightTech/Cognitech-terraform-iac-modules.git
   cd Cognitech-terraform-iac-modules
   ```

2. **Deploy Foundation Infrastructure**
   ```bash
   # Deploy KMS keys for state encryption
   aws cloudformation create-stack \
     --stack-name terraform-kms-dual-region \
     --template-body file://Cloudformation/Initializing-account-for-terraform/kms-keys-dual-region.yaml \
     --parameters ParameterKey=OrganizationId,ParameterValue=your-org-id \
     --capabilities CAPABILITY_IAM

   # Deploy Terraform backend
   aws cloudformation create-stack \
     --stack-name terraform-backend \
     --template-body file://Cloudformation/Initializing-account-for-terraform/bucket-and-state-lock.yaml
   ```

3. **Configure Terraform Backend**
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "your-account-region-network-config-state"
       key            = "path/to/terraform.tfstate"
       region         = "us-east-1"
       encrypt        = true
       kms_key_id     = "alias/terraform-state-key-us-east-1"
       dynamodb_table = "your-account-region-state-lock"
     }
   }
   ```

### Deployment Sequence

Follow this order for initial setup:

1. **Foundation** → Deploy KMS keys and Terraform backend
2. **Authentication** → Setup GitHub OIDC integration
3. **Networking** → Deploy VPC and network components
4. **Security** → Configure security groups and policies
5. **Applications** → Deploy application-specific infrastructure

---

## CloudFormation Templates

### Foundation Templates

#### 🔐 KMS Keys for Multi-Region State Encryption

**Location**: `Cloudformation/Initializing-account-for-terraform/kms-keys-dual-region.yaml`

Creates KMS keys in both primary and secondary regions for Terraform state encryption with organization-wide access controls.

**Key Features**:
- ✅ **Dual-region deployment** from a single stack
- ✅ **Organization-scoped access** with minimal permissions
- ✅ **Automatic key rotation** for enhanced security
- ✅ **Nested stack architecture** for scalability
- ✅ **Comprehensive tagging** and naming conventions

**Security Model**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnableRootAdminPermissions",
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::${AWS::AccountId}:root"},
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "AllowUseOfKeyForOrganization",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"],
      "Resource": "*",
      "Condition": {
        "StringEquals": {"aws:PrincipalOrgID": "${OrganizationId}"}
      }
    }
  ]
}
```

**Parameters**:
| Parameter | Description | Default |
|-----------|-------------|---------|
| `PrimaryRegion` | Primary AWS region | `us-east-1` |
| `SecondaryRegion` | Secondary AWS region | `us-west-2` |
| `KeyAlias` | KMS key alias prefix | `terraform-state-key` |
| `Environment` | Environment tag | `dev` |
| `OrganizationId` | AWS Organization ID | `o-orvtyisdyc` |

**Deployment**:
```bash
aws cloudformation create-stack \
  --stack-name terraform-kms-dual-region \
  --template-body file://Cloudformation/Initializing-account-for-terraform/kms-keys-dual-region.yaml \
  --parameters ParameterKey=PrimaryRegion,ParameterValue=us-east-1 \
               ParameterKey=SecondaryRegion,ParameterValue=us-west-2 \
               ParameterKey=OrganizationId,ParameterValue=your-org-id \
  --capabilities CAPABILITY_IAM
```

#### 🚀 Terraform Backend Infrastructure

**Templates**:
- `bucket-and-state-lock.yaml` - S3 and DynamoDB backend setup
- `github-iam-role.yaml` - GitHub Actions OIDC integration

**Purpose**: Establishes secure, scalable Terraform state management with CI/CD integration.

**Infrastructure Components**:
- **Primary S3 Bucket**: Terraform state storage with versioning
- **Secondary S3 Bucket**: Cross-region backup and disaster recovery
- **DynamoDB Table**: State locking mechanism
- **GitHub OIDC Provider**: Secure CI/CD authentication
- **IAM Roles**: GitHub Actions execution permissions

**Security Features**:
- ✅ TLS-only access policies
- ✅ Public access blocked
- ✅ Versioning and backup enabled
- ✅ OIDC-based authentication (no long-lived keys)

**Deployment Sequence**:

1. **Deploy Backend Infrastructure**:
   ```bash
   aws cloudformation create-stack \
     --stack-name terraform-backend \
     --template-body file://Cloudformation/Initializing-account-for-terraform/bucket-and-state-lock.yaml \
     --region us-east-1
   ```

2. **Deploy GitHub OIDC Integration**:
   ```bash
   aws cloudformation create-stack \
     --stack-name github-oidc \
     --template-body file://Cloudformation/Initializing-account-for-terraform/github-iam-role.yaml \
     --capabilities CAPABILITY_NAMED_IAM \
     --region us-east-1
   ```

---

## Terraform Modules

### Core Infrastructure Modules

Located in `terraform/modules/`, these reusable modules provide standardized infrastructure components:

#### Network Infrastructure
- **`vpc/`** - Virtual Private Cloud with multi-AZ support
- **`subnets/`** - Public and private subnet configurations
- **`natgateway/`** - NAT Gateway for outbound internet access
- **`Routes/`** - Route table configurations
- **`Security-group/`** - Security group templates

#### Compute & Storage
- **`EC2-instance/`** - EC2 instance templates with user data
- **`Load-Balancers/`** - Application and Network Load Balancers
- **`Target-groups/`** - ALB/NLB target group configurations
- **`S3-Private-bucket/`** - Secure S3 bucket templates

#### Security & Compliance
- **`IAM-Roles/`** - IAM role and policy templates
- **`IAM-User/`** - IAM user management
- **`EC2-key-pair/`** - EC2 key pair management
- **`Secrets-manager/`** - AWS Secrets Manager integration

#### Monitoring & Management
- **`SSM-Parameter-store/`** - Systems Manager parameters
- **`AWSBackup/`** - Backup and recovery policies

### Backend Configuration Examples

#### Primary Region Configuration
```hcl
terraform {
  backend "s3" {
    bucket         = "${account_name}-${region}-network-config-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "alias/terraform-state-key-us-east-1"
    dynamodb_table = "${account_name}-${region}-state-lock"
  }
}
```

#### Secondary Region Configuration
```hcl
terraform {
  backend "s3" {
    bucket         = "${account_name}-${region}-network-config-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    kms_key_id     = "alias/terraform-state-key-us-west-2"
    dynamodb_table = "${account_name}-${region}-state-lock"
  }
}
```

### Module Usage Example

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  common = {
    global        = true
    tags          = local.common_tags
    account_name  = var.account_name
    region_prefix = var.region_prefix
  }
  
  vpc = {
    name       = "${var.account_name}-vpc"
    cidr_block = "10.0.0.0/16"
  }
}
```

---

## Security & Cost Considerations

**Security:**
- ✅ **Minimal permissions** - Only root admin and organization-wide access
- ✅ **Organization boundary** - Access restricted to your AWS Organization
- ✅ **Automatic rotation** enabled for enhanced security
- ✅ **No unnecessary service roles** - Clean permission model

**Cost:**
- Each KMS key costs $1/month (total: $2/month for both regions)
- Additional charges apply for key operations (encrypt/decrypt)
- Consider using the same key for multiple state files in the same region

## Troubleshooting

1. **Permission Denied**: Ensure the OrganizationId parameter matches your actual AWS Organization
2. **Nested Stack Issues**: CloudFormation automatically handles the JSON template embedding
3. **Region Availability**: Verify KMS is available in your target regions
4. **Organization Access**: Principals must be within the specified AWS Organization to use the keys
5. **Domain/DNS Issues**: Verify your public domain and hosted zone are properly configured
6. **Identity Center Roles**: Ensure Admin and NetworkAdministrator roles are properly configured in AWS Identity Center
# Initializing Account for Terraform

This directory contains CloudFormation templates required to set up the foundational infrastructure for Terraform in an AWS account. These templates prepare your AWS account for Infrastructure as Code (IaC) operations using Terraform.

## Overview

Before you can start deploying infrastructure with Terraform, you need to establish:

1. **Remote state storage** - A secure S3 bucket to store Terraform state files
2. **State locking mechanism** - A DynamoDB table to prevent concurrent Terraform operations
3. **CI/CD authentication** - GitHub OIDC provider and IAM role for GitHub Actions

## Templates

### 1. bucket-and-state-lock.yaml

**Purpose**: Creates the Terraform backend infrastructure for remote state management.

**Resources Created**:

- **Primary S3 Bucket**: Stores Terraform state files with versioning enabled
- **Secondary S3 Bucket**: Backup bucket in a different region for disaster recovery
- **DynamoDB Table**: Provides state locking to prevent concurrent Terraform runs
- **S3 Bucket Policies**: Enforces security policies including TLS encryption

**Key Features**:

- ✅ Versioning enabled on S3 buckets
- ✅ Public access blocked on all buckets
- ✅ TLS encryption enforced
- ✅ Cross-region backup capability
- ✅ Pay-per-request billing for DynamoDB

**Parameters**:

- `pAccountName`: Account name (from SSM Parameter `/standard/AWSAccount`)
- `pAccountNameLC`: Account name in lowercase (from SSM Parameter `/standard/AWSAccountLC`)
- `TableName`: DynamoDB table name (default: `terragrunt-lock-table`)
- `pSecondaryRegion`: Secondary region for backup (default: `us-west-2`)

### 2. github-iam-role.yaml

**Purpose**: Sets up GitHub Actions integration with AWS using OpenID Connect (OIDC).

**Resources Created**:

- **GitHub OIDC Provider**: Enables secure authentication from GitHub Actions
- **IAM Role**: Allows GitHub Actions to assume AWS permissions
- **IAM Policy**: Grants necessary permissions for infrastructure operations

**Key Features**:

- ✅ Secure OIDC-based authentication (no long-lived access keys)
- ✅ Repository-scoped access control
- ✅ Configurable organization/user scope
- ✅ Full AWS permissions for infrastructure management

**Parameters**:

- `pAccountName`: Account name (from SSM Parameter `/standard/AWSAccount`)
- `pAccountNameLC`: Account name in lowercase (from SSM Parameter `/standard/AWSAccountLC`)
- `pGitHubOrg`: GitHub organization or username (default: `KahBrightTech`)
- `pAppName`: Application name for role identification (default: `OIDCGitHubRole`)

## Deployment Order

Deploy these templates in the following sequence:

### Step 1: Deploy Terraform Backend

```bash
aws cloudformation create-stack \
  --stack-name terraform-backend \
  --template-body file://bucket-and-state-lock.yaml \
  --region us-east-1
```

### Step 2: Deploy GitHub OIDC Integration

```bash
aws cloudformation create-stack \
  --stack-name github-oidc \
  --template-body file://github-iam-role.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

## Prerequisites

Before deploying these templates, ensure:

1. **SSM Parameters**: The following SSM parameters must exist:
   - `/standard/AWSAccount` - Your AWS account name
   - `/standard/AWSAccountLC` - Your AWS account name in lowercase

2. **AWS CLI**: Configured with appropriate permissions to create:
   - S3 buckets and policies
   - DynamoDB tables
   - IAM roles, policies, and OIDC providers

3. **GitHub Repository**: Have your GitHub organization/username ready for OIDC configuration

4. **Ansible Tower** (Optional): For automation and configuration management:
   - Create a new account at [Red Hat Developer Portal](https://developers.redhat.com/products/ansible/download)
   - Download Ansible Tower version 2.4 (recommended version for current compatibility)
   - Upload the downloaded package to the data transfer S3 bucket (this bucket will be used for deployments)

## Post-Deployment Configuration

### 1. Configure Terraform Backend

After deploying the backend infrastructure, configure your Terraform projects to use the remote backend:

```hcl
terraform {
  backend "s3" {
    bucket         = "<account-name-lc>-<region>-network-config-state"
    key            = "path/to/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "<account-name-lc>-<region>-state-lock"
    encrypt        = true
  }
}
```

### 2. Configure GitHub Actions

Add the following secrets to your GitHub repository:

- `AWS_ROLE_TO_ASSUME`: The ARN of the created IAM role (from CloudFormation outputs)

Example GitHub Actions workflow:

```yaml
jobs:
  terraform:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
          aws-region: us-east-1
```

## Security Considerations

- **Least Privilege**: Consider customizing the IAM policy in `github-iam-role.yaml` to follow the principle of least privilege
- **Repository Scope**: The OIDC configuration allows access from any repository in the specified organization
- **State File Security**: Terraform state files may contain sensitive information; ensure proper access controls
- **Backup Strategy**: The secondary S3 bucket provides disaster recovery capabilities

## Outputs

Both templates provide useful outputs:

**bucket-and-state-lock.yaml**:

- `S3BucketName`: Primary state bucket name
- `S3BucketNameSecondary`: Secondary state bucket name
- `DynamoDBTableName`: State lock table name

**github-iam-role.yaml**:

- `GitHubOIDCProviderArn`: OIDC provider ARN
- `GitHubActionsRoleArn`: IAM role ARN for GitHub Actions

## Troubleshooting

### Common Issues

1. **Stack creation fails**: Ensure SSM parameters exist and AWS CLI has sufficient permissions
2. **OIDC authentication fails**: Verify GitHub organization name and repository permissions
3. **State locking issues**: Check DynamoDB table permissions and network connectivity

### Useful Commands

```bash
# Check stack status
aws cloudformation describe-stacks --stack-name terraform-backend

# View stack outputs
aws cloudformation describe-stacks --stack-name terraform-backend --query 'Stacks[0].Outputs'

# Delete stacks (cleanup)
aws cloudformation delete-stack --stack-name github-oidc
aws cloudformation delete-stack --stack-name terraform-backend
```

## Best Practices & Guidelines

### Infrastructure Standards
- **Naming Convention**: All resources follow the pattern `${AccountName}-${Region}-${ResourceType}-${Purpose}`
- **Tagging Strategy**: Consistent tagging across all resources for cost tracking and governance
- **Security First**: All templates include security best practices and least privilege principles
- **Multi-Region**: Templates support multi-region deployments for high availability

### Security Considerations
- **KMS Encryption**: All state files and sensitive data encrypted with customer-managed KMS keys
- **IAM Policies**: Implement least privilege access patterns
- **Network Security**: Private subnets for sensitive workloads with NAT Gateway for outbound access
- **Backup Strategy**: Automated backup policies for critical infrastructure
- **State File Security**: Terraform state files may contain sensitive information; ensure proper access controls
- **Repository Scope**: The OIDC configuration allows access from any repository in the specified organization

### Deployment Workflow
1. **Plan Phase**: Always run `terraform plan` to review changes
2. **State Management**: Use remote state with DynamoDB locking
3. **Environment Isolation**: Separate state files for different environments
4. **Change Management**: Use version control and approval processes

---

## Support & Troubleshooting

### Common Issues

#### KMS Key Access Denied
```bash
# Verify organization membership
aws organizations describe-organization
aws sts get-caller-identity
```

#### Stack Creation Failures
```bash
# Check stack status
aws cloudformation describe-stacks --stack-name terraform-backend

# View stack events
aws cloudformation describe-stack-events --stack-name terraform-backend
```

#### Terraform State Lock
```bash
# Release stuck lock
terraform force-unlock <LOCK-ID>
```

#### OIDC Authentication Issues
```bash
# Verify OIDC provider
aws iam get-open-id-connect-provider --open-id-connect-provider-arn <provider-arn>
```

### Backend Configuration Validation
```bash
# Verify backend access
aws s3 ls s3://your-state-bucket
aws dynamodb describe-table --table-name your-lock-table
```

### Useful Administrative Commands
```bash
# View stack outputs
aws cloudformation describe-stacks --stack-name terraform-backend --query 'Stacks[0].Outputs'

# Validate CloudFormation template
aws cloudformation validate-template --template-body file://template.yaml

# Clean up resources (use with caution)
aws cloudformation delete-stack --stack-name github-oidc
aws cloudformation delete-stack --stack-name terraform-backend
```

### Logging & Monitoring
- CloudTrail logging enabled for all API calls
- CloudWatch monitoring for infrastructure metrics
- AWS Config for compliance monitoring
- VPC Flow Logs for network analysis

---

## Contributing

### Development Guidelines
1. **Test First**: Validate all changes in a development environment
2. **Documentation**: Update this README if parameters or outputs change
3. **Template Validation**: Use `aws cloudformation validate-template` before deployment
4. **Impact Assessment**: Consider the impact on existing Terraform state files
5. **Follow Standards**: Use consistent variable naming conventions and module structure

### Module Structure
```
module-name/
├── main.tf          # Primary resource definitions
├── variables.tf     # Input variables
├── outputs.tf       # Output values
├── providers.tf     # Provider configuration
└── README.md        # Module documentation
```

### Code Review Process
1. Follow the existing module structure
2. Include comprehensive documentation
3. Add example usage in module README
4. Test in non-production environment first
5. Submit pull requests for infrastructure team review

---

## Environment-Specific Notes

**Note**: These templates are designed for the KahBrightTech organization. Modify the default values and hardcoded account IDs as needed for your environment.

### Customization Requirements
- Update Organization ID in KMS policies
- Modify GitHub organization names in OIDC configuration
- Adjust region-specific configurations
- Update account-specific naming conventions

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## Contact

For questions, issues, or contributions:
- Create an issue in this repository
- Contact the infrastructure team
- Review individual module README files for specific guidance
- Consult AWS documentation for service-specific requirements
