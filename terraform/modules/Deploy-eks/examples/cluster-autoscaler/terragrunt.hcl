# Cluster Autoscaler Example

This directory contains an example configuration for deploying an EKS cluster with Cluster Autoscaler enabled.

## Usage

1. Update the `cluster-autoscaler-policy.json` file:
   - Replace `${CLUSTER_NAME}` with your actual cluster name

2. Create/update your Terragrunt configuration:
   ```hcl
   include "root" {
     path = find_in_parent_folders()
   }

   terraform {
     source = "../../modules/Deploy-eks"
   }

   inputs = {
     common = {
       account_name     = "myaccount"
       region_prefix    = "use1"
       tags = {
         Environment = "dev"
         ManagedBy   = "terraform"
       }
     }

     eks = {
       key                      = "main"
       name                     = "my-cluster"
       version                  = "1.30"
       role_arn                 = "arn:aws:iam::123456789012:role/eks-cluster-role"
       subnet_ids               = ["subnet-xxx", "subnet-yyy"]
       endpoint_private_access  = true
       endpoint_public_access   = true
       oidc_thumbprint          = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
       
       create_node_group        = true
       
       # Enable Cluster Autoscaler
       eks_addons = {
         enable_vpc_cni                = true
         enable_kube_proxy             = true
         enable_coredns                = true
         enable_cluster_autoscaler     = true
         cluster_autoscaler_version    = "9.43.2"
         cluster_autoscaler_role_key   = "cluster_autoscaler_role"
       }
       
       # IAM role for Cluster Autoscaler
       create_service_accounts = true
       iam_roles = [
         {
           key                       = "cluster_autoscaler_role"
           name                      = "eks-cluster-autoscaler-role"
           service_account_name      = "cluster-autoscaler"
           service_account_namespace = "kube-system"
           policy_files              = ["${path.module}/cluster-autoscaler-policy.json"]
         }
       ]
       
       # Node groups configuration
       eks_node_groups = [
         {
           key             = "main"
           name            = "main-node-group"
           node_role_arn   = "arn:aws:iam::123456789012:role/eks-node-role"
           subnet_ids      = ["subnet-xxx", "subnet-yyy"]
           
           scaling_config = {
             desired_size = 2
             min_size     = 1
             max_size     = 10
           }
           
           update_config = {
             max_unavailable_percentage = 33
           }
           
           instance_types = ["t3.medium"]
           capacity_type  = "ON_DEMAND"
           
           tags = {
             "k8s.io/cluster-autoscaler/my-cluster" = "owned"
             "k8s.io/cluster-autoscaler/enabled"    = "true"
           }
         }
       ]
       
       # Key pair for SSH access
       key_pair = {
         name           = "eks-node-key"
         secret_name    = "eks-node-private-key"
         secret_description = "Private key for EKS nodes"
       }
     }
   }
   ```

3. Deploy:
   ```bash
   terragrunt apply
   ```

## Verification

After deployment, verify the Cluster Autoscaler is running:

```bash
# Set your cluster name
export CLUSTER_NAME=my-cluster

# Update kubeconfig
aws eks update-kubeconfig --name $CLUSTER_NAME --region us-east-1

# Check Cluster Autoscaler pod
kubectl get pods -n kube-system | grep cluster-autoscaler

# View logs
kubectl logs -n kube-system -l app.kubernetes.io/name=cluster-autoscaler --tail=50
```

## Testing Autoscaling

Test scale-up:
```bash
# Create a deployment that requires more resources
kubectl create deployment scale-test --image=nginx
kubectl scale deployment scale-test --replicas=50

# Watch nodes
kubectl get nodes -w

# Check Cluster Autoscaler logs
kubectl logs -n kube-system -l app.kubernetes.io/name=cluster-autoscaler -f
```

Test scale-down:
```bash
# Delete the deployment
kubectl delete deployment scale-test

# Wait 10-15 minutes and observe nodes scaling down
kubectl get nodes -w
```

## Customization

You can customize the Cluster Autoscaler behavior by modifying the module configuration. See the main README.md for available options.
