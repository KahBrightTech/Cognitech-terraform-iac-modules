# Cluster Autoscaler for EKS

This example demonstrates how to enable and configure the Kubernetes Cluster Autoscaler on your EKS cluster.

## Overview

The Cluster Autoscaler automatically adjusts the size of your Kubernetes cluster when:
- Pods fail to run due to insufficient resources
- Nodes are underutilized for an extended period

## Prerequisites

1. An EKS cluster with node groups
2. An IAM role for the Cluster Autoscaler service account with appropriate permissions

## IAM Policy

The Cluster Autoscaler requires an IAM role with the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeScalingActivities",
        "autoscaling:DescribeTags",
        "ec2:DescribeImages",
        "ec2:DescribeInstanceTypes",
        "ec2:DescribeLaunchTemplateVersions",
        "ec2:GetInstanceTypesFromInstanceRequirements",
        "eks:DescribeNodegroup"
      ],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## Configuration Example

```hcl
eks = {
  key  = "main"
  name = "my-eks-cluster"
  
  # Enable node group creation
  create_node_group = true
  
  # Enable Cluster Autoscaler
  eks_addons = {
    enable_cluster_autoscaler    = true
    cluster_autoscaler_version   = "9.43.2"  # Helm chart version
    cluster_autoscaler_role_key  = "cluster_autoscaler_role"  # Reference to IAM role
  }
  
  # IAM role configuration
  iam_roles = [
    {
      key                        = "cluster_autoscaler_role"
      name                       = "eks-cluster-autoscaler-role"
      service_account_name       = "cluster-autoscaler"
      service_account_namespace  = "kube-system"
      policy_files               = ["path/to/cluster-autoscaler-policy.json"]
    }
  ]
  
  # Node group configuration with autoscaling tags
  eks_node_groups = [
    {
      key           = "main"
      name          = "main-node-group"
      scaling_config = {
        desired_size = 2
        min_size     = 1
        max_size     = 10
      }
      # Additional configuration...
    }
  ]
}
```

## Important Notes

### Node Group Tags

Ensure your node groups have the following tags for autodiscovery:

```hcl
tags = {
  "k8s.io/cluster-autoscaler/${cluster_name}" = "owned"
  "k8s.io/cluster-autoscaler/enabled"         = "true"
}
```

These tags are automatically added by the module when using EKS managed node groups.

### Version Compatibility

The Cluster Autoscaler version must match your Kubernetes version:

| Kubernetes Version | Cluster Autoscaler Chart Version |
|-------------------|----------------------------------|
| 1.30              | 9.43.x                          |
| 1.29              | 9.37.x                          |
| 1.28              | 9.35.x                          |
| 1.27              | 9.29.x                          |

### Configuration Options

The module configures the Cluster Autoscaler with the following defaults:

- `balance-similar-node-groups`: true - Balances scaling across similar node groups
- `skip-nodes-with-system-pods`: false - Allows downscaling of nodes with system pods
- `expander`: least-waste - Uses least-waste strategy for selecting node groups to scale

## Verification

After deployment, verify the Cluster Autoscaler is running:

```bash
# Check pod status
kubectl get pods -n kube-system | grep cluster-autoscaler

# Check logs
kubectl logs -n kube-system -l app.kubernetes.io/name=cluster-autoscaler

# Check service account
kubectl get sa cluster-autoscaler -n kube-system -o yaml
```

## Testing

To test the Cluster Autoscaler:

1. Deploy a workload that exceeds current capacity:
```bash
kubectl create deployment test-scale --image=nginx --replicas=50
```

2. Watch the cluster autoscaler logs:
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=cluster-autoscaler -f
```

3. Verify new nodes are added:
```bash
kubectl get nodes -w
```

4. Clean up:
```bash
kubectl delete deployment test-scale
```

## Troubleshooting

### Pods not scaling up

- Verify IAM role has correct permissions
- Check node group has capacity (max_size)
- Review Cluster Autoscaler logs for errors

### Nodes not scaling down

- Check if pods have PodDisruptionBudgets
- Verify nodes don't have pods with local storage
- Review scale-down delay settings

### Permission errors

- Ensure IAM role is correctly annotated on service account
- Verify OIDC provider is configured
- Check trust relationship in IAM role

## Additional Resources

- [Cluster Autoscaler Documentation](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
- [AWS EKS Best Practices for Cluster Autoscaler](https://aws.github.io/aws-eks-best-practices/cluster-autoscaling/)
- [Cluster Autoscaler Helm Chart](https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler)
