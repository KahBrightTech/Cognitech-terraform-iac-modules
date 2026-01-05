# AWS Load Balancer Controller Example

This example demonstrates how to deploy the AWS Load Balancer Controller to an EKS cluster using Terragrunt.

## Prerequisites

1. **Existing EKS Cluster**: You need an existing EKS cluster
2. **IAM Policy**: Create the AWS Load Balancer Controller IAM policy

### Create IAM Policy

Download and create the IAM policy:

```bash
# Download the policy document
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.8.1/docs/install/iam_policy.json

# Create the policy
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json
```

## Directory Structure

```
.
├── terragrunt.hcl          # This configuration file
└── README.md               # This file
```

## Configuration

The `terragrunt.hcl` file contains:

- **Helm Release**: Deploys AWS Load Balancer Controller v1.8.1
- **IAM Role for Service Account (IRSA)**: Configured for the controller
- **Service Account**: Created in kube-system namespace
- **Minimal Node Group**: Optional, adjust based on your needs

## Usage

### 1. Update Dependencies

Modify the dependency paths in `terragrunt.hcl` to match your structure:

```hcl
dependency "eks" {
  config_path = "../eks-cluster"  # Path to your EKS cluster module
}

dependency "vpc" {
  config_path = "../vpc"  # Path to your VPC module
}
```

### 2. Adjust Configuration

Update these values as needed:

```hcl
locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  common      = local.common_vars.locals.common
  account_id  = get_aws_account_id()
  region      = get_aws_region()
}
```

### 3. Deploy

```bash
# Initialize
terragrunt init

# Plan
terragrunt plan

# Apply
terragrunt apply
```

### 4. Verify Deployment

```bash
# Check if controller is running
kubectl get deployment -n kube-system aws-load-balancer-controller

# Check pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check service account
kubectl describe sa aws-load-balancer-controller -n kube-system

# View logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

## Configuration Options

### Helm Chart Version

To use a different version:

```hcl
eks_addons = {
  enable_aws_load_balancer_controller  = true
  aws_load_balancer_controller_version = "1.8.1"  # Change this
}
```

### IAM Policy

The configuration expects this policy to exist:
```
arn:aws:iam::{account_id}:policy/AWSLoadBalancerControllerIAMPolicy
```

If your policy has a different name, update:

```hcl
iam_roles = {
  aws-lb-controller = {
    managed_policy_arns = [
      "arn:aws:iam::${local.account_id}:policy/YourCustomPolicyName"
    ]
  }
}
```

## Testing the Load Balancer Controller

### Create a Test Application

```yaml
# test-app.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: test-alb
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: test-alb
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: test-alb
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  namespace: test-alb
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-service
                port:
                  number: 80
```

Apply the test:

```bash
kubectl apply -f test-app.yaml

# Check ingress
kubectl get ingress -n test-alb

# Get ALB address
kubectl get ingress nginx-ingress -n test-alb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Subnet Tagging Requirements

Ensure your subnets have the proper tags for ALB/NLB creation:

### Public Subnets (for internet-facing load balancers)
```
kubernetes.io/role/elb = 1
```

### Private Subnets (for internal load balancers)
```
kubernetes.io/role/internal-elb = 1
```

### Cluster-specific Tag
```
kubernetes.io/cluster/{cluster-name} = shared
```

## Troubleshooting

### Controller Not Starting

**Check controller logs:**
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

**Common issues:**
- IAM role not properly configured
- OIDC provider not set up correctly
- Missing IAM permissions

### ALB Not Created

**Check ingress events:**
```bash
kubectl describe ingress -n test-alb nginx-ingress
```

**Common issues:**
- Missing subnet tags
- Security group configuration
- VPC ID mismatch
- IAM permissions

### IRSA Not Working

**Verify service account annotation:**
```bash
kubectl describe sa aws-load-balancer-controller -n kube-system
```

Should show:
```
Annotations: eks.amazonaws.com/role-arn: arn:aws:iam::{account}:role/...
```

**Check OIDC provider:**
```bash
aws iam list-open-id-connect-providers
```

## Outputs

After deployment, access these outputs:

```bash
# View Helm release information
terragrunt output helm_aws_load_balancer_controller

# View IAM role ARN
terragrunt output iam_roles
```

## Clean Up

```bash
# Remove test application
kubectl delete -f test-app.yaml

# Destroy infrastructure
terragrunt destroy
```

## Additional Resources

- [AWS Load Balancer Controller Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [AWS Load Balancer Controller GitHub](https://github.com/kubernetes-sigs/aws-load-balancer-controller)
- [EKS User Guide - ALB Ingress Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)
- [Subnet Auto-Discovery](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.8/deploy/subnet_discovery/)
