# ECR Module Examples

This directory contains examples demonstrating how to use the ECR Terraform module.

## Examples Included

### 1. Basic ECR Repository
A simple ECR repository with default settings suitable for development environments.

### 2. Production ECR Repository with Lifecycle Policy
An ECR repository configured for production with:
- Immutable image tags
- Comprehensive lifecycle policy for image retention
- Automatic cleanup of old and untagged images

### 3. Shared ECR Repository with Cross-Account Access
An ECR repository configured for sharing images across AWS accounts with:
- Cross-account repository policy
- Read-only access for external accounts
- Push/pull access for specific IAM roles

## Usage

1. **Update the account IDs**: Replace the placeholder account IDs in the repository policies with your actual AWS account IDs.

2. **Configure AWS credentials**: Ensure your AWS credentials are configured:
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-east-1"
   ```

3. **Initialize Terraform**:
   ```bash
   cd examples
   terraform init
   ```

4. **Review the plan**:
   ```bash
   terraform plan
   ```

5. **Apply the configuration**:
   ```bash
   terraform apply
   ```

6. **View outputs**:
   ```bash
   terraform output
   ```

## Customization

You can customize these examples by:
- Changing the repository names
- Modifying lifecycle policies to match your retention requirements
- Adjusting encryption settings
- Adding or removing cross-account access
- Configuring replication to other regions

## Cleanup

To destroy the created resources:
```bash
terraform destroy
```

**Note**: If `force_delete` is set to `false` and the repository contains images, you'll need to either:
1. Manually delete all images first, or
2. Set `force_delete = true` in the configuration before destroying

## Docker Usage Examples

After creating the ECR repositories, you can use them with Docker:

### Login to ECR
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### Tag an image
```bash
docker tag myapp:latest <repository-url>:latest
```

### Push an image
```bash
docker push <repository-url>:latest
```

### Pull an image
```bash
docker pull <repository-url>:latest
```

## Best Practices

1. **Use immutable tags in production** to ensure image integrity
2. **Enable scan_on_push** to automatically scan for vulnerabilities
3. **Implement lifecycle policies** to manage storage costs
4. **Use KMS encryption** for sensitive container images
5. **Apply least-privilege repository policies** for cross-account access
6. **Tag images with semantic versions** (e.g., v1.0.0) for better tracking
7. **Set force_delete to false** in production to prevent accidental deletion

## Troubleshooting

### Authentication errors
If you encounter authentication errors when pushing/pulling images:
- Verify your AWS credentials are valid
- Ensure your IAM user/role has the necessary ECR permissions
- Check that the repository policy allows your principal

### Lifecycle policy not working
- Lifecycle policies can take up to 24 hours to take effect
- Verify the policy JSON syntax is correct
- Check CloudWatch Logs for lifecycle policy execution logs

### Cross-account access issues
- Ensure both the repository policy and the IAM policy in the target account allow access
- Verify account IDs are correct in the policy
- Check that the principal format is correct (arn:aws:iam::ACCOUNT-ID:root or specific role)
