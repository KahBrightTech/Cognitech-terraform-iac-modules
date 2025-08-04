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

## Contributing

When modifying these templates:

1. Test changes in a development environment first
2. Update this README if parameters or outputs change
3. Validate templates using `aws cloudformation validate-template`
4. Consider the impact on existing Terraform state files

---

**Note**: These templates are designed for the KahBrightTech organization. Modify the default values and hardcoded account IDs as needed for your environment.
