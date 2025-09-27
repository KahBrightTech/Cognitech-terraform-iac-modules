# AWS VPC Endpoints Terraform Module

This Terraform module creates AWS VPC Endpoints for secure communication between your VPC and AWS services without internet access. The module supports both Gateway and Interface endpoints with comprehensive configuration options.

## Features

- ✅ **Dual Endpoint Support**: Supports both Gateway and Interface VPC endpoints
- ✅ **Auto-Detection**: Automatically determines endpoint type based on service name
- ✅ **Security Groups**: Configurable security group rules for Interface endpoints
- ✅ **DNS Configuration**: Private DNS and custom DNS record IP types
- ✅ **Policy Management**: Custom IAM policies or default allow-all policies
- ✅ **Route Tables**: Support for multiple route table associations
- ✅ **Tagging**: Comprehensive resource tagging with customizable naming

## Supported Services

### Gateway Endpoints
- **Amazon S3** (`com.amazonaws.<region>.s3`)
- **Amazon DynamoDB** (`com.amazonaws.<region>.dynamodb`)

### Interface Endpoints
- **Amazon EC2** (`com.amazonaws.<region>.ec2`)
- **AWS Lambda** (`com.amazonaws.<region>.lambda`)
- **Amazon SNS** (`com.amazonaws.<region>.sns`)
- **Amazon SQS** (`com.amazonaws.<region>.sqs`)
- **AWS Secrets Manager** (`com.amazonaws.<region>.secretsmanager`)
- **AWS Systems Manager** (`com.amazonaws.<region>.ssm`)
- And many more AWS services...

## Usage Examples

### Basic S3 Gateway Endpoint

```hcl
module "s3_vpc_endpoint" {
  source = "./modules/AWSVPCEndpoints"

  vpc_endpoints = {
    vpc_id             = "vpc-12345678"
    service_name       = "com.amazonaws.us-west-2.s3"
    service_name_short = "s3"
    
    route_table_ids = [
      "rtb-12345678",
      "rtb-87654321"
    ]
  }

  common = {
    global        = false
    tags          = {
      Environment = "production"
      Team        = "platform"
    }
    account_name  = "mycompany"
    region_prefix = "usw2"
  }
}
```

### Interface Endpoint with Security Groups

```hcl
module "lambda_vpc_endpoint" {
  source = "./modules/AWSVPCEndpoints"

  vpc_endpoints = {
    vpc_id             = "vpc-12345678"
    service_name       = "com.amazonaws.us-west-2.lambda"
    service_name_short = "lambda"
    endpoint_type      = "Interface"
    
    subnet_ids = [
      "subnet-12345678",
      "subnet-87654321"
    ]
    
    security_group_ids = [
      "sg-12345678"
    ]
    
    private_dns_enabled = true
    dns_record_ip_type  = "ipv4"
  }

  common = {
    global        = false
    tags          = {
      Environment = "production"
      Service     = "lambda-integration"
    }
    account_name  = "mycompany"
    region_prefix = "usw2"
  }
}
```

### Endpoint with Custom Policy

```hcl
data "aws_iam_policy_document" "s3_endpoint_policy" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    
    resources = [
      "arn:aws:s3:::my-secure-bucket/*"
    ]
    
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalVpc"
      values   = ["vpc-12345678"]
    }
  }
}

module "s3_vpc_endpoint_with_policy" {
  source = "./modules/AWSVPCEndpoints"

  vpc_endpoints = {
    vpc_id             = "vpc-12345678"
    service_name       = "com.amazonaws.us-west-2.s3"
    service_name_short = "s3"
    policy_document    = data.aws_iam_policy_document.s3_endpoint_policy.json
    
    route_table_ids = ["rtb-12345678"]
  }

  common = {
    global        = false
    tags          = {
      Environment = "production"
      Purpose     = "secure-s3-access"
    }
    account_name  = "mycompany"
    region_prefix = "usw2"
  }
}
```

### Multiple Endpoints Configuration

```hcl
# S3 Gateway Endpoint
module "s3_endpoint" {
  source = "./modules/AWSVPCEndpoints"

  vpc_endpoints = {
    vpc_id             = var.vpc_id
    service_name       = "com.amazonaws.${var.region}.s3"
    service_name_short = "s3"
    route_table_ids    = var.private_route_table_ids
  }
  
  common = var.common_config
}

# Lambda Interface Endpoint
module "lambda_endpoint" {
  source = "./modules/AWSVPCEndpoints"

  vpc_endpoints = {
    vpc_id             = var.vpc_id
    service_name       = "com.amazonaws.${var.region}.lambda"
    service_name_short = "lambda"
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.vpc_endpoints.id]
  }
  
  common = var.common_config
}

# Secrets Manager Interface Endpoint
module "secretsmanager_endpoint" {
  source = "./modules/AWSVPCEndpoints"

  vpc_endpoints = {
    vpc_id             = var.vpc_id
    service_name       = "com.amazonaws.${var.region}.secretsmanager"
    service_name_short = "secretsmgr"
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.vpc_endpoints.id]
    
    additional_security_group_rules = [
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr]
        description = "HTTPS access from VPC"
      }
    ]
  }
  
  common = var.common_config
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.5 |
| aws | >= 4.37.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.37.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| common | Common variables used by all resources | `object({...})` | n/a | yes |
| vpc_endpoints | Configuration object for VPC Endpoint with all sub-variables | `object({...})` | n/a | yes |

### vpc_endpoints Object Structure

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_id | The ID of the VPC in which the endpoint will be used | `string` | n/a | yes |
| service_name | The service name for the VPC endpoint | `string` | n/a | yes |
| service_name_short | Short name for the service (used in resource naming) | `string` | `null` | no |
| endpoint_name | Name for the VPC endpoint | `string` | `null` | no |
| endpoint_type | The VPC endpoint type (Gateway or Interface) | `string` | `null` | no |
| auto_accept | Accept the VPC endpoint | `bool` | `null` | no |
| route_table_ids | One or more route table IDs for Gateway endpoints | `list(string)` | `[]` | no |
| additional_route_table_ids | Additional route table IDs to associate | `list(string)` | `null` | no |
| subnet_ids | The ID of one or more subnets for Interface endpoints | `list(string)` | `[]` | no |
| security_group_ids | Security groups for Interface endpoints | `list(string)` | `[]` | no |
| private_dns_enabled | Enable private hosted zone for Interface endpoints | `bool` | `true` | no |
| dns_record_ip_type | DNS records type (ipv4, dualstack, or ipv6) | `string` | `null` | no |
| enable_policy | Whether to enable a default policy | `bool` | `false` | no |
| policy_document | Custom policy document for the VPC endpoint | `string` | `null` | no |
| additional_security_group_rules | Additional security group rules | `list(object({...}))` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_endpoint_id | The ID of the VPC endpoint |
| vpc_endpoint_arn | The Amazon Resource Name (ARN) of the VPC endpoint |
| vpc_endpoint_state | The state of the VPC endpoint |
| vpc_endpoint_dns_entry | The DNS entries for the VPC endpoint |
| vpc_endpoint_network_interface_ids | Network interfaces for Interface endpoints |
| vpc_endpoint_prefix_list_id | Prefix list ID for Gateway endpoints |
| vpc_endpoint_cidr_blocks | CIDR blocks for Gateway endpoints |
| endpoint_type | The type of VPC endpoint (Gateway or Interface) |
| endpoint_name | The name assigned to the VPC endpoint |
| dns_names | DNS names for Interface endpoints |
| hosted_zone_ids | Hosted zone IDs for Interface endpoints |
| route_table_association_ids | Route table association IDs for Gateway endpoints |

## Common Service Names by Region

Replace `<region>` with your AWS region (e.g., `us-west-2`, `eu-west-1`):

### Gateway Endpoints
- **S3**: `com.amazonaws.<region>.s3`
- **DynamoDB**: `com.amazonaws.<region>.dynamodb`

### Interface Endpoints
- **EC2**: `com.amazonaws.<region>.ec2`
- **Lambda**: `com.amazonaws.<region>.lambda`
- **SNS**: `com.amazonaws.<region>.sns`
- **SQS**: `com.amazonaws.<region>.sqs`
- **Secrets Manager**: `com.amazonaws.<region>.secretsmanager`
- **Systems Manager**: `com.amazonaws.<region>.ssm`
- **ECS**: `com.amazonaws.<region>.ecs`
- **ECR API**: `com.amazonaws.<region>.ecr.api`
- **ECR DKR**: `com.amazonaws.<region>.ecr.dkr`
- **CloudWatch**: `com.amazonaws.<region>.monitoring`
- **CloudWatch Logs**: `com.amazonaws.<region>.logs`

## Best Practices

1. **Security Groups**: For Interface endpoints, use restrictive security groups that only allow necessary traffic
2. **Subnets**: Deploy Interface endpoints across multiple AZs for high availability
3. **DNS**: Enable private DNS for Interface endpoints to use standard AWS service URLs
4. **Policies**: Use least privilege IAM policies for VPC endpoints to restrict access
5. **Monitoring**: Monitor VPC endpoint usage through CloudWatch metrics
6. **Cost**: Gateway endpoints are free, but Interface endpoints incur hourly charges

## License

This module is released under the MIT License. See [LICENSE](LICENSE) for details.