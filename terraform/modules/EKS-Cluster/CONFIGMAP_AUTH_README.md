# EKS Cluster ConfigMap Authentication Guide

This guide explains how to use the optional ConfigMap authentication method alongside the modern EKS Access Entry API.

## Overview

By default, this module uses the **modern EKS Access Entry API** for cluster authentication. However, you can optionally enable **ConfigMap-based authentication** (the legacy `aws-auth` ConfigMap method) for backward compatibility or specific use cases.

## When to Use ConfigMap Authentication

- **Legacy integrations**: Third-party tools that only support ConfigMap-based authentication
- **Migration scenarios**: Gradually migrating from ConfigMap to Access Entry API
- **Hybrid requirements**: Need to support both authentication methods simultaneously

> **Note**: For new deployments, using Access Entry API only (default) is recommended.

## Prerequisites

To use ConfigMap authentication, ensure:
1. `authentication_mode` is set to `"API_AND_CONFIG_MAP"` (default) or `"CONFIG_MAP"`
2. The Kubernetes provider is configured (already included in this module)
3. You have the necessary IAM role/user ARNs to map

## Configuration Variables

### Basic Configuration

```hcl
module "eks_cluster" {
  source = "./modules/EKS-Cluster"

  common = {
    account_name  = "mycompany"
    region_prefix = "usw2"
    tags          = { Environment = "dev" }
    global        = false
  }

  eks_cluster = {
    name       = "my-cluster"
    role_arn   = "arn:aws:iam::123456789012:role/eks-cluster-role"
    subnet_ids = ["subnet-abc123", "subnet-def456"]
    
    # Enable ConfigMap authentication
    enable_configmap_auth = true
    
    # Define roles to map
    configmap_roles = [
      {
        rolearn  = "arn:aws:iam::123456789012:role/DevOpsTeamRole"
        username = "devops:{{SessionName}}"
        groups   = ["system:masters"]
      },
      {
        rolearn  = "arn:aws:iam::123456789012:role/DeveloperRole"
        username = "developer"
        groups   = ["developers"]
      }
    ]
    
    # Define users to map (optional)
    configmap_users = [
      {
        userarn  = "arn:aws:iam::123456789012:user/john.doe"
        username = "john"
        groups   = ["system:masters"]
      }
    ]
    
    key_pair = {
      create_secret = false
    }
  }
}
```

## Variable Details

### `enable_configmap_auth`
- **Type**: `bool`
- **Default**: `false`
- **Description**: Enables the ConfigMap authentication method

### `configmap_roles`
- **Type**: `list(object)`
- **Default**: `[]`
- **Description**: List of IAM roles to map to Kubernetes users/groups

Each role object contains:
- `rolearn` (string): The ARN of the IAM role
- `username` (string): The Kubernetes username to map to
  - Can use `{{SessionName}}` for assumed role sessions
  - Can use `{{EC2PrivateDNSName}}` for node roles
- `groups` (list(string)): List of Kubernetes groups to assign

### `configmap_users`
- **Type**: `list(object)`
- **Default**: `[]`
- **Description**: List of IAM users to map to Kubernetes users/groups

Each user object contains:
- `userarn` (string): The ARN of the IAM user
- `username` (string): The Kubernetes username to map to
- `groups` (list(string)): List of Kubernetes groups to assign

## Common Kubernetes Groups

| Group | Permissions |
|-------|-------------|
| `system:masters` | Full cluster admin access |
| `system:nodes` | Node permissions (for worker nodes) |
| `system:bootstrappers` | Bootstrap permissions (for worker nodes) |
| Custom groups | Can be bound to custom RBAC roles |

## Example Configurations

### Example 1: Admin Role Only

```hcl
eks_cluster = {
  name                  = "production-cluster"
  role_arn              = "arn:aws:iam::123456789012:role/eks-cluster-role"
  subnet_ids            = ["subnet-abc123", "subnet-def456"]
  enable_configmap_auth = true
  
  configmap_roles = [
    {
      rolearn  = "arn:aws:iam::123456789012:role/AdminRole"
      username = "admin"
      groups   = ["system:masters"]
    }
  ]
  
  configmap_users = []
  
  key_pair = {
    create_secret = false
  }
}
```

### Example 2: Multiple Roles with Different Permissions

```hcl
eks_cluster = {
  name                  = "dev-cluster"
  role_arn              = "arn:aws:iam::123456789012:role/eks-cluster-role"
  subnet_ids            = ["subnet-abc123", "subnet-def456"]
  enable_configmap_auth = true
  
  configmap_roles = [
    {
      rolearn  = "arn:aws:iam::123456789012:role/EKS-Node-Role"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    },
    {
      rolearn  = "arn:aws:iam::123456789012:role/AdminRole"
      username = "admin:{{SessionName}}"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::123456789012:role/ReadOnlyRole"
      username = "readonly"
      groups   = ["view-only"]
    }
  ]
  
  configmap_users = []
  
  key_pair = {
    create_secret = false
  }
}
```

### Example 3: SSO Role with Session Name

```hcl
eks_cluster = {
  name                  = "sso-cluster"
  role_arn              = "arn:aws:iam::123456789012:role/eks-cluster-role"
  subnet_ids            = ["subnet-abc123", "subnet-def456"]
  enable_configmap_auth = true
  
  configmap_roles = [
    {
      rolearn  = "arn:aws:iam::123456789012:role/AWSReservedSSO_DeveloperAccess_abc123"
      username = "sso-developer:{{SessionName}}"
      groups   = ["developers"]
    }
  ]
  
  configmap_users = []
  
  key_pair = {
    create_secret = false
  }
}
```

### Example 4: Mixed Roles and Users

```hcl
eks_cluster = {
  name                  = "mixed-auth-cluster"
  role_arn              = "arn:aws:iam::123456789012:role/eks-cluster-role"
  subnet_ids            = ["subnet-abc123", "subnet-def456"]
  enable_configmap_auth = true
  
  configmap_roles = [
    {
      rolearn  = "arn:aws:iam::123456789012:role/TeamLeadRole"
      username = "team-lead"
      groups   = ["system:masters"]
    }
  ]
  
  configmap_users = [
    {
      userarn  = "arn:aws:iam::123456789012:user/alice"
      username = "alice"
      groups   = ["developers"]
    },
    {
      userarn  = "arn:aws:iam::123456789012:user/bob"
      username = "bob"
      groups   = ["testers"]
    }
  ]
  
  key_pair = {
    create_secret = false
  }
}
```

## Using with Custom RBAC Roles

If you're using custom Kubernetes groups (not `system:masters`), you'll need to create RBAC roles and bindings:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: developer-role
rules:
- apiGroups: ["*"]
  resources: ["pods", "services", "deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: developer-binding
subjects:
- kind: Group
  name: developers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: developer-role
  apiGroup: rbac.authorization.k8s.io
```

## Disabling ConfigMap Authentication

To disable ConfigMap authentication (use Access Entry API only):

```hcl
eks_cluster = {
  name                  = "api-only-cluster"
  role_arn              = "arn:aws:iam::123456789012:role/eks-cluster-role"
  subnet_ids            = ["subnet-abc123", "subnet-def456"]
  
  # ConfigMap auth disabled by default
  enable_configmap_auth = false
  
  # These will be ignored when enable_configmap_auth = false
  configmap_roles = []
  configmap_users = []
  
  key_pair = {
    create_secret = false
  }
}
```

## Combining ConfigMap and Access Entry Methods

When using `authentication_mode = "API_AND_CONFIG_MAP"`, you can use both methods simultaneously:

```hcl
eks_cluster = {
  name                  = "hybrid-cluster"
  role_arn              = "arn:aws:iam::123456789012:role/eks-cluster-role"
  subnet_ids            = ["subnet-abc123", "subnet-def456"]
  authentication_mode   = "API_AND_CONFIG_MAP"  # Default
  
  # Modern API method (handled automatically by module for admin role)
  # Additional roles can be added via aws_eks_access_entry resources
  
  # Legacy ConfigMap method
  enable_configmap_auth = true
  configmap_roles = [
    {
      rolearn  = "arn:aws:iam::123456789012:role/LegacyAppRole"
      username = "legacy-app"
      groups   = ["legacy-group"]
    }
  ]
  
  key_pair = {
    create_secret = false
  }
}
```

> **Important**: Avoid managing the same IAM principal in both ConfigMap and Access Entry to prevent conflicts.

## Troubleshooting

### ConfigMap Not Created
- Ensure `enable_configmap_auth = true`
- Verify `authentication_mode` is set to `"API_AND_CONFIG_MAP"` or `"CONFIG_MAP"`
- Check that the Kubernetes provider can authenticate to the cluster

### Access Denied After ConfigMap Update
- Verify the IAM role/user ARNs are correct
- Ensure the groups specified exist or are valid system groups
- Check that the IAM principal is assuming the correct role

### Conflicts Between ConfigMap and Access Entry
- Don't manage the same IAM principal in both methods
- Use one method for each IAM principal

## Migration Path

**Recommended approach to migrate from ConfigMap to Access Entry API:**

1. Set `authentication_mode = "API_AND_CONFIG_MAP"`
2. Keep existing ConfigMap entries
3. Add new access via Access Entry API
4. Gradually remove entries from ConfigMap
5. Once all entries migrated, set `enable_configmap_auth = false`
6. Eventually set `authentication_mode = "API"` (once fully migrated)

## Best Practices

1. **Prefer Access Entry API** for new deployments
2. **Use IAM roles** instead of IAM users when possible
3. **Use `{{SessionName}}`** for SSO and assumed roles for better audit trails
4. **Limit use of `system:masters`** - create custom RBAC roles for least privilege
5. **Document your mappings** - maintain a record of which IAM principals have cluster access
6. **Test access** after making changes to ensure proper permissions

## Additional Resources

- [AWS EKS Access Entry Documentation](https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html)
- [AWS EKS Authentication Modes](https://docs.aws.amazon.com/eks/latest/userguide/grant-k8s-access.html)
- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
