# KMS Keys for Terraform Dual-Region Setup

This folder contains a CloudFormation template to create KMS keys in two regions simultaneously for Terraform state encryption with organization-wide access.

## Template

### `kms-keys-dual-region.yaml`
A streamlined template that creates KMS keys in both primary and secondary regions from a single stack deployment.

**Features:**
- ✅ Creates KMS keys in both regions simultaneously
- ✅ **Organization-wide access only** (exactly as you specified)
- ✅ **Clean permission model** - only root admin and organization access
- ✅ Uses nested stack approach for secondary region
- ✅ Automatic key rotation enabled
- ✅ Proper tagging and naming conventions

## Key Policy (Simplified)

The template implements exactly the permission structure you provided:

```json
{
  "Version": "2012-10-17",
  "Id": "org-wide-access-example",
  "Statement": [
    {
      "Sid": "EnableRootAdminPermissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${AWS::AccountId}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "AllowUseOfKeyForOrganization",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalOrgID": "${OrganizationId}"
        }
      }
    }
  ]
}
```

## Parameters

- `PrimaryRegion`: Primary region for KMS key (default: us-east-1)
- `SecondaryRegion`: Secondary region for KMS key (default: us-west-2)
- `KeyAlias`: Alias name for the KMS keys (default: 'terraform-state-key')
- `Environment`: Environment tag (dev/staging/prod)
- `OrganizationId`: AWS Organization ID (default: 'o-orvtyisdyc')

## Deployment Instructions

Deploy this single template to create KMS keys in both regions:

```bash
aws cloudformation create-stack \
  --stack-name terraform-kms-dual-region \
  --template-body file://kms-keys-dual-region.yaml \
  --parameters ParameterKey=PrimaryRegion,ParameterValue=us-east-1 \
               ParameterKey=SecondaryRegion,ParameterValue=us-west-2 \
               ParameterKey=KeyAlias,ParameterValue=terraform-state \
               ParameterKey=Environment,ParameterValue=prod \
               ParameterKey=OrganizationId,ParameterValue=o-orvtyisdyc \
  --capabilities CAPABILITY_IAM
```

## Prerequisites

Before deploying this template, ensure you have:

1. **AWS Organization Setup**: The OrganizationId parameter must match your actual AWS Organization ID
2. **Proper Permissions**: KMS permissions to create keys and CloudFormation permissions to deploy nested stacks
3. **Region Availability**: Ensure KMS is available in both target regions
4. **Public Domain Required**: You must have a public domain available for this setup to work properly. The domain will be used for:
   - SSL certificate validation (if using HTTPS endpoints)
   - DNS resolution for Terraform state bucket access
   - Potential custom domain configurations for API endpoints
   - Proper routing and accessibility for cross-region operations

   **Note**: Without a public domain, certain features may not function correctly, especially in production environments where secure access and proper DNS resolution are critical.

## Usage with Terraform

Once the KMS keys are created, reference them in your Terraform backend:

**Primary Region:**
```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket-primary"
    key            = "path/to/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "alias/terraform-state-key-us-east-1"
    dynamodb_table = "terraform-state-lock"
  }
}
```

**Secondary Region:**
```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket-secondary"
    key            = "path/to/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    kms_key_id     = "alias/terraform-state-key-us-west-2"
    dynamodb_table = "terraform-state-lock"
  }
}
```

## Outputs

The template provides outputs for both regions:

**Primary Region:**
- **PrimaryKMSKeyId** - The KMS key ID
- **PrimaryKMSKeyArn** - The full ARN of the KMS key
- **PrimaryKMSKeyAlias** - The alias reference for the key

**Secondary Region:**
- **SecondaryKMSKeyId** - The KMS key ID
- **SecondaryKMSKeyArn** - The full ARN of the KMS key
- **SecondaryKMSKeyAlias** - The alias reference for the key

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
