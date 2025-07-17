# EC2 Key Pair Module

This Terraform module creates EC2 key pairs with RSA 4096-bit encryption and optionally stores the private key in AWS Secrets Manager for secure access and management.

## Features

- **RSA 4096-bit Encryption**: Generates secure RSA key pairs with 4096-bit keys
- **AWS Secrets Manager Integration**: Optionally stores private keys in Secrets Manager
- **Automatic Tagging**: Applies consistent naming and tagging conventions
- **Secure Key Management**: Private keys are handled securely through Terraform state

## Prerequisites

- AWS provider configured with appropriate permissions
- IAM permissions for EC2 key pair creation
- IAM permissions for Secrets Manager (if using secret storage)

## Usage with Terragrunt

### Basic Key Pair (Without Secrets Manager)

Create a `terragrunt.hcl` file in your formation directory:

```hcl
# terragrunt.hcl
terraform {
  source = "git::https://github.com/KahBrightTech/Cognitech-terraform-iac-modules.git//terraform/modules/EC2-key-pair?ref=main"
}

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  common = {
    global        = false
    tags          = {
      Environment = "production"
      Project     = "web-infrastructure"
      Owner       = "infrastructure-team"
    }
    account_name  = "production"
    region_prefix = "us-east-1"
  }
  
  key_pair = {
    name          = "web-servers-key"
    create_secret = false
  }
}
```

### Key Pair with Secrets Manager Storage

```hcl
inputs = {
  common = {
    global        = false
    tags          = {
      Environment = "production"
      Project     = "database-infrastructure"
      Owner       = "database-team"
    }
    account_name  = "production"
    region_prefix = "us-east-1"
  }
  
  key_pair = {
    name               = "database-servers-key"
    create_secret      = true
    secret_name        = "db-servers-private-key"
    secret_description = "Private key for database server access"
    policy             = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Principal = {
            AWS = "arn:aws:iam::ACCOUNT-ID:role/DatabaseAdministrators"
          }
          Action = "secretsmanager:GetSecretValue"
          Resource = "*"
        }
      ]
    })
  }
}
```

### Multiple Key Pairs

```hcl
# For multiple key pairs, use separate module calls
inputs = {
  common = {
    global        = false
    tags          = {
      Environment = "production"
      Project     = "multi-tier-app"
    }
    account_name  = "production"
    region_prefix = "us-east-1"
  }
  
  key_pair = {
    name          = "web-tier-key"
    create_secret = true
    secret_name   = "web-tier-private-key"
  }
}
```

## Input Variables

### `common`

- **Description**: Common variables used by all resources
- **Type**: `object({...})`
- **Required**: Yes

Object structure:

- `global` (bool): Whether this is a global resource
- `tags` (map(string)): Tags to apply to all resources
- `account_name` (string): Name of the AWS account
- `region_prefix` (string): AWS region prefix
- `account_name_abr` (string, optional): Abbreviated account name

### `key_pair`

- **Description**: Key pair configuration for EC2 instances
- **Type**: `object({...})`
- **Required**: Yes

Object structure:

- `name` (string): Name of the key pair
- `secret_name` (string, optional): Name for the secret in Secrets Manager
- `secret_description` (string, optional): Description for the secret
- `policy` (string, optional): IAM policy for the secret access
- `create_secret` (bool): Whether to store the private key in Secrets Manager

## Outputs

### `key_pair_name`

- **Description**: The name of the created key pair
- **Type**: `string`

### `key_pair_id`

- **Description**: The ID of the created key pair
- **Type**: `string`

### `private_key_pem`

- **Description**: The private key in PEM format
- **Type**: `string`
- **Sensitive**: Yes

### `public_key_openssh`

- **Description**: The public key in OpenSSH format
- **Type**: `string`

### `secret_arn`

- **Description**: ARN of the secret in Secrets Manager (if created)
- **Type**: `string`

## Security Considerations

### Private Key Management

1. **State File Security**: Private keys are stored in Terraform state - ensure state files are encrypted and access is restricted
2. **Secrets Manager**: Use Secrets Manager for production environments to avoid storing keys in state files
3. **Access Control**: Implement proper IAM policies for secret access
4. **Key Rotation**: Consider regular key rotation policies

### Best Practices

1. **Use Secrets Manager**: Always use Secrets Manager for production environments
2. **Least Privilege**: Grant minimum necessary permissions for secret access
3. **Audit Access**: Monitor secret access through CloudTrail
4. **Backup Keys**: Ensure you have secure backups of critical keys
5. **Key Naming**: Use descriptive names for easy identification

## Usage Examples

### Connecting to EC2 Instance

After creating the key pair, you can use it to connect to EC2 instances:

```bash
# If private key is stored locally
ssh -i path/to/private-key.pem ec2-user@instance-ip

# If using Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id web-tier-private-key \
  --query SecretString --output text > temp-key.pem
chmod 600 temp-key.pem
ssh -i temp-key.pem ec2-user@instance-ip
rm temp-key.pem
```

### PowerShell (Windows)

```powershell
# Retrieve private key from Secrets Manager
$SecretValue = Get-SECSecretValue -SecretId "web-tier-private-key"
$PrivateKey = $SecretValue.SecretString
$PrivateKey | Out-File -FilePath "temp-key.pem" -Encoding UTF8

# Use with SSH client
ssh -i temp-key.pem ec2-user@instance-ip

# Clean up
Remove-Item "temp-key.pem"
```

## Common Use Cases

- **Web Servers**: SSH access to web server instances
- **Database Servers**: Secure access to database instances
- **Development Environments**: Developer access to development instances
- **Bastion Hosts**: Key pairs for jump boxes and bastion hosts
- **Application Servers**: Access to application server instances

## Troubleshooting

### Common Issues

1. **Permission Denied**: Check file permissions on private key (should be 600)
2. **Key Not Found**: Ensure the key pair name matches what was created
3. **Secrets Manager Access**: Verify IAM permissions for secret access
4. **SSH Connection Issues**: Check security group rules and network ACLs

### Debugging Steps

1. Verify key pair exists in AWS console
2. Check Secrets Manager for stored private key
3. Validate IAM permissions for secret access
4. Test SSH connection with verbose output (`ssh -v`)

## Module Structure

```text
EC2-key-pair/
├── main.tf       # Main resource definitions
├── variables.tf  # Input variable definitions
├── outputs.tf    # Output definitions
├── providers.tf  # Provider configurations
└── README.md     # This file
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |
| tls | >= 3.0 |

## Resources

| Name | Type |
|------|------|
| aws_caller_identity.current | data source |
| aws_region.current | data source |
| aws_iam_roles.admin_role | data source |
| aws_iam_roles.network_role | data source |
| tls_private_key.key | resource |
| aws_key_pair.generated_key | resource |
| aws_secretsmanager_secret.private_key | resource |
| aws_secretsmanager_secret_version.private_key | resource |

## Key Specifications

- **Algorithm**: RSA
- **Key Size**: 4096 bits
- **Format**: PEM (private), OpenSSH (public)
- **Encryption**: TLS provider generates secure keys

## IAM Permissions Required

### For Key Pair Creation

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateKeyPair",
        "ec2:DescribeKeyPairs",
        "ec2:DeleteKeyPair"
      ],
      "Resource": "*"
    }
  ]
}
```

### For Secrets Manager (if used)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:CreateSecret",
        "secretsmanager:PutSecretValue",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:DeleteSecret"
      ],
      "Resource": "*"
    }
  ]
}
```
