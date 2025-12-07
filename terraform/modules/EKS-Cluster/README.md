# EKS Cluster Module

This Terraform module creates and manages an Amazon EKS (Elastic Kubernetes Service) cluster with modern access management using the EKS Access Entry API.

## Features

- EKS Cluster creation with configurable networking and access settings
- Modern EKS Access Entry API for IAM principal access management
- Support for multiple IAM principals with different EKS policies
- OIDC provider for IAM roles for service accounts (IRSA)
- Optional networking add-ons (VPC CNI, kube-proxy)
- Optional application add-ons (CoreDNS, metrics-server)
- EC2 key pair generation and secrets management for EC2-based node groups
- Flexible authentication modes

## Prerequisites

- AWS Provider >= 4.37.0
- Terraform >= 1.5.5
- Valid IAM role for the EKS cluster
- VPC with subnets for the cluster

## Usage

### Basic Example

```hcl
module "eks_cluster" {
  source = "./modules/EKS-Cluster"

  common = {
    account_name  = "mycompany"
    region_prefix = "usw2"
    tags = {
      Environment = "production"
      ManagedBy   = "Terraform"
    }
    global = false
  }

  eks_cluster = {
    name       = "my-cluster"
    role_arn   = "arn:aws:iam::123456789012:role/eks-cluster-role"
    subnet_ids = ["subnet-abc123", "subnet-def456", "subnet-ghi789"]
    
    access_entries = {
      "cluster_admins" = {
        principal_arns = [
          "arn:aws:iam::123456789012:role/AdminRole",
          "arn:aws:iam::123456789012:role/DevOpsRole"
        ]
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      }
      "developers" = {
        principal_arns = [
          "arn:aws:iam::123456789012:role/DeveloperRole"
        ]
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
      }
    }
    
    key_pair = {
      create_secret = false
    }
  }
}
```

### Advanced Example with Multiple Access Policies

```hcl
module "eks_cluster" {
  source = "./modules/EKS-Cluster"

  common = {
    account_name  = "mycompany"
    region_prefix = "usw2"
    tags = {
      Environment = "production"
      ManagedBy   = "Terraform"
      Team        = "Platform"
    }
    global = false
  }

  eks_cluster = {
    name    = "production-cluster"
    version = "1.32"
    role_arn = "arn:aws:iam::123456789012:role/eks-cluster-role"
    subnet_ids = [
      "subnet-private-1",
      "subnet-private-2",
      "subnet-private-3"
    ]
    
    # Access control using modern API
    access_entries = {
      "cluster_admins" = {
        principal_arns = [
          "arn:aws:iam::123456789012:role/AWSReservedSSO_AdministratorAccess_abc123",
          "arn:aws:iam::123456789012:role/PlatformTeamRole"
        ]
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      }
      "full_access" = {
        principal_arns = [
          "arn:aws:iam::123456789012:role/SRETeamRole"
        ]
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
      }
      "editors" = {
        principal_arns = [
          "arn:aws:iam::123456789012:role/EngineerRole",
          "arn:aws:iam::123456789012:role/DevOpsRole"
        ]
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
      }
      "viewers" = {
        principal_arns = [
          "arn:aws:iam::123456789012:role/ReadOnlyRole",
          "arn:aws:iam::123456789012:role/AuditorRole"
        ]
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
      }
    }
    
    # Network configuration
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["10.0.0.0/8"]
    
    # Authentication
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
    
    # Logging
    enabled_cluster_log_types = [
      "api",
      "audit",
      "authenticator",
      "controllerManager",
      "scheduler"
    ]
    
    # Add-ons
    enable_networking_addons   = true
    enable_application_addons  = true
    
    # OIDC
    oidc_thumbprint = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
    
    # Key pair for EC2 nodes
    is_this_ec2_node_group = true
    key_pair = {
      name               = "eks-node-key"
      secret_name        = "eks-node-private-key"
      secret_description = "Private key for EKS EC2 nodes"
      create_secret      = true
    }
  }
}
```

## Input Variables

### `common` (required)

Common variables used across all resources.

| Variable | Type | Description |
|----------|------|-------------|
| `account_name` | string | Account name used in resource naming |
| `region_prefix` | string | Region prefix (e.g., "usw2" for us-west-2) |
| `tags` | map(string) | Common tags to apply to all resources |
| `global` | bool | Whether resources are global |
| `account_name_abr` | string | Optional account name abbreviation |

### `eks_cluster` (required)

EKS cluster configuration.

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `name` | string | - | Name of the EKS cluster |
| `role_arn` | string | - | ARN of the IAM role for the EKS cluster |
| `subnet_ids` | list(string) | - | List of subnet IDs for the cluster |
| `access_entries` | map(object) | `{}` | Map of access entry groups with principal ARNs and policies |
| `version` | string | `"1.32"` | Kubernetes version |
| `oidc_thumbprint` | string | `null` | OIDC thumbprint for IRSA |
| `is_this_ec2_node_group` | bool | `false` | Whether using EC2-based node groups |
| `enable_networking_addons` | bool | `true` | Enable VPC CNI and kube-proxy add-ons |
| `enable_application_addons` | bool | `false` | Enable CoreDNS and metrics-server add-ons |
| `endpoint_private_access` | bool | `false` | Enable private API endpoint access |
| `endpoint_public_access` | bool | `true` | Enable public API endpoint access |
| `public_access_cidrs` | list(string) | `["0.0.0.0/0"]` | CIDRs allowed to access public endpoint |
| `authentication_mode` | string | `"API_AND_CONFIG_MAP"` | Authentication mode |
| `bootstrap_cluster_creator_admin_permissions` | bool | `true` | Grant cluster creator admin permissions |
| `enabled_cluster_log_types` | list(string) | `[]` | Types of cluster logs to enable |

#### `access_entries` Structure

The `access_entries` variable is a map where each key represents a group name and the value is an object with:

- `principal_arns` (list(string)): List of IAM principal ARNs (roles/users) to grant access
- `policy_arn` (string): The EKS access policy ARN to apply

**Available EKS Access Policies:**

| Policy ARN | Description |
|------------|-------------|
| `arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy` | Full cluster administrator access |
| `arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy` | Full access to all resources |
| `arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy` | Edit access to most resources |
| `arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy` | Read-only access to resources |

#### `key_pair` Structure (required when `is_this_ec2_node_group = true`)

| Variable | Type | Description |
|----------|------|-------------|
| `name` | string | Name for the key pair |
| `name_prefix` | string | Name prefix for the key pair |
| `secret_name` | string | Name for the Secrets Manager secret |
| `secret_description` | string | Description for the secret |
| `policy` | string | IAM policy JSON for the secret |
| `create_secret` | bool | Whether to create a secret for the private key |

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_id` | The name/ID of the EKS cluster |
| `cluster_arn` | The ARN of the EKS cluster |
| `cluster_endpoint` | The endpoint for the EKS cluster API |
| `cluster_security_group_id` | Security group ID attached to the EKS cluster |
| `cluster_iam_role_arn` | IAM role ARN used by the EKS cluster |
| `cluster_certificate_authority_data` | Base64 encoded certificate data |
| `cluster_version` | The Kubernetes server version for the cluster |
| `oidc_provider_arn` | ARN of the OIDC provider for IRSA |
| `key_pair_name` | Name of the generated key pair (if created) |
| `private_key_secret_arn` | ARN of the secret containing the private key (if created) |

## Access Management Examples

### Single Admin Role

```hcl
access_entries = {
  "admins" = {
    principal_arns = ["arn:aws:iam::123456789012:role/AdminRole"]
    policy_arn     = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  }
}
```

### Multiple Roles with Same Policy

```hcl
access_entries = {
  "platform_team" = {
    principal_arns = [
      "arn:aws:iam::123456789012:role/TeamLead",
      "arn:aws:iam::123456789012:role/SeniorEngineer",
      "arn:aws:iam::123456789012:role/OnCallEngineer"
    ]
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  }
}
```

### Tiered Access (Multiple Groups)

```hcl
access_entries = {
  "admins" = {
    principal_arns = [
      "arn:aws:iam::123456789012:role/AdminRole"
    ]
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  }
  "developers" = {
    principal_arns = [
      "arn:aws:iam::123456789012:role/DevRole1",
      "arn:aws:iam::123456789012:role/DevRole2"
    ]
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
  }
  "readonly" = {
    principal_arns = [
      "arn:aws:iam::123456789012:role/ReadOnlyRole",
      "arn:aws:iam::123456789012:role/AuditorRole"
    ]
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  }
}
```

### SSO Roles

```hcl
access_entries = {
  "sso_admins" = {
    principal_arns = [
      "arn:aws:iam::123456789012:role/AWSReservedSSO_AdministratorAccess_abc123"
    ]
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  }
  "sso_developers" = {
    principal_arns = [
      "arn:aws:iam::123456789012:role/AWSReservedSSO_DeveloperAccess_def456"
    ]
    policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
  }
}
```

## Authentication Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| `API` | Use only EKS Access Entry API | Recommended for new clusters |
| `CONFIG_MAP` | Use only aws-auth ConfigMap | Legacy compatibility |
| `API_AND_CONFIG_MAP` | Use both methods | Migration scenarios |

> **Note**: The ConfigMap authentication method has been removed from this module. For ConfigMap-based authentication, please refer to the [CONFIGMAP_AUTH_README.md](./CONFIGMAP_AUTH_README.md) for historical reference.

## Add-ons

### Networking Add-ons
- **vpc-cni**: Amazon VPC CNI plugin for pod networking
- **kube-proxy**: Kubernetes network proxy

### Application Add-ons
- **coredns**: DNS service for Kubernetes
- **metrics-server**: Metrics aggregation for autoscaling

> **Note**: Application add-ons require nodes to be running in the cluster.

## Best Practices

1. **Use Access Entry API** - Prefer the modern EKS Access Entry API over ConfigMap authentication
2. **Principle of Least Privilege** - Grant only the necessary permissions using appropriate policies
3. **Group by Function** - Organize access entries by team or function for better management
4. **Use IAM Roles** - Prefer IAM roles over users for better security and automation
5. **Enable Logging** - Enable cluster logging for audit and troubleshooting
6. **Private Endpoints** - Consider using private endpoints for production workloads
7. **OIDC for Workloads** - Use IRSA (IAM Roles for Service Accounts) for pod-level IAM permissions
8. **Version Management** - Keep Kubernetes version up to date with AWS recommendations

## Migration from ConfigMap to Access Entry API

If you're migrating from the ConfigMap authentication method:

1. Ensure `authentication_mode = "API_AND_CONFIG_MAP"` (default)
2. Define your access entries in the `access_entries` variable
3. Test access with the new method
4. Once validated, you can remove ConfigMap entries
5. Eventually switch to `authentication_mode = "API"` for full migration

## Troubleshooting

### Access Denied Errors
- Verify the principal ARN is correct and exists
- Check that the principal is assuming the correct role
- Ensure the policy ARN is valid and appropriate for the use case

### Add-ons Not Installing
- Verify networking add-ons are enabled for basic cluster functionality
- Ensure nodes are running before enabling application add-ons
- Check cluster logs for detailed error messages

### OIDC Issues
- Verify the OIDC thumbprint is correct
- Ensure the OIDC provider is created successfully
- Check IAM role trust relationships for IRSA

## Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [EKS Access Entry API](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

## License

This module is maintained by your organization. Please refer to your organization's licensing terms.
