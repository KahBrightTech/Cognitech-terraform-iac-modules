# AWS Load Balancer Controller - Terragrunt Configuration

This is a standalone Terragrunt configuration for deploying the AWS Load Balancer Controller to an existing EKS cluster using Helm.

---

## Basic Configuration

### Minimal EKS Cluster with Load Balancer Controller

```hcl
# terragrunt.hcl

terraform {
  source = "git::https://github.com/KahBrightTech/Cognitech-terraform-iac-modules.git//terraform/modules/Deploy-eks?ref=main"
}

include "root" {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  common      = local.common_vars.locals.common
  region      = local.common_vars.locals.region
}

inputs = {
  common = local.common

  eks = {
    key                     = "main"
    name                    = "primary"
    role_arn                = "arn:aws:iam::123456789012:role/eks-cluster-role"
    subnet_ids              = ["subnet-xxx", "subnet-yyy", "subnet-zzz"]
    vpc_id                  = "vpc-xxxxx"
    endpoint_private_access = true
    endpoint_public_access  = true
    version                 = "1.32"
    oidc_thumbprint         = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
    create_node_group       = true
    create_service_accounts = true

    eks_addons = {
      enable_vpc_cni                      = true
      enable_kube_proxy                   = true
      enable_coredns                      = true
      enable_aws_load_balancer_controller = true
      
      vpc_cni_version                          = "v1.18.0-eksbuild.1"
      kube_proxy_version                       = "v1.32.0-eksbuild.2"
      coredns_version                          = "v1.11.1-eksbuild.9"
      aws_load_balancer_controller_version     = "1.8.1"
      
      # Reference to IAM role for Load Balancer Controller
      aws_load_balancer_controller_role_key = "aws-lb-controller"
    }

    # Key pair for node group SSH access
    key_pair = {
      name               = "eks-nodes-keypair"
      secret_name        = "eks-nodes-private-key"
      secret_description = "Private key for EKS node group"
    }

    # Access entries for cluster access
    access_entries = {
      admin_group = {
        principal_arns = ["arn:aws:iam::123456789012:role/AdminRole"]
        policy_arn     = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      }
    }

    # IAM Roles for Service Accounts (IRSA)
    iam_roles = {
      aws-lb-controller = {
        key                        = "aws-lb-controller"
        name                       = "eks-aws-load-balancer-controller"
        description                = "IAM role for AWS Load Balancer Controller"
        service_account_namespace  = "kube-system"
        service_account_name       = "aws-load-balancer-controller"
        
        managed_policy_arns = [
          "arn:aws:iam::123456789012:policy/AWSLoadBalancerControllerIAMPolicy"
        ]
      }
    }

    # Launch template for node group
    launch_templates = [{
      key           = "default"
      name          = "eks-nodes-launch-template"
      instance_type = "t3.medium"
      
      vpc_security_group_keys = ["eks_cluster_sg_id"]
      
      block_device_mappings = [{
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 50
          volume_type           = "gp3"
          delete_on_termination = true
          encrypted             = true
        }
      }]
    }]

    # EKS Node Group
    eks_node_groups = [{
      key                  = "default"
      name                 = "default-node-group"
      launch_template_key  = "default"
      
      scaling_config = {
        desired_size = 2
        max_size     = 4
        min_size     = 1
      }
      
      update_config = {
        max_unavailable = 1
      }
    }]
  }
}
```

---

## AWS Load Balancer Controller Setup

### Prerequisites

Before enabling the AWS Load Balancer Controller, you need to:

1. **Create IAM Policy for Load Balancer Controller**

Download the policy:
```bash
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.8.1/docs/install/iam_policy.json
```

Create the policy:
```bash
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json
```

2. **Configure the Module**

The module expects:
- `enable_aws_load_balancer_controller = true`
- `aws_load_balancer_controller_version` (e.g., "1.8.1")
- `aws_load_balancer_controller_role_key` or `aws_load_balancer_controller_role_arn`
- `vpc_id` must be provided

### Configuration Options

```hcl
eks_addons = {
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller_version = "1.8.1"
  
  # Option 1: Use role key (references iam_roles)
  aws_load_balancer_controller_role_key = "aws-lb-controller"
  
  # Option 2: Use direct role ARN
  # aws_load_balancer_controller_role_arn = "arn:aws:iam::123456789012:role/eks-aws-lb-controller"
}
```

---

## Complete Example with All Features

```hcl
# terragrunt.hcl

terraform {
  source = "git::https://github.com/KahBrightTech/Cognitech-terraform-iac-modules.git//terraform/modules/Deploy-eks?ref=main"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "iam" {
  config_path = "../iam"
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  common      = local.common_vars.locals.common
  account_id  = get_aws_account_id()
  region      = get_aws_region()
}

inputs = {
  common = local.common

  eks = {
    key     = "production"
    name    = "prod-cluster"
    role_arn = dependency.iam.outputs.eks_cluster_role_arn
    
    # Network Configuration
    subnet_ids              = dependency.vpc.outputs.private_subnet_ids
    vpc_id                  = dependency.vpc.outputs.vpc_id
    endpoint_private_access = true
    endpoint_public_access  = false
    
    # Kubernetes Configuration
    version                                     = "1.32"
    service_ipv4_cidr                          = "172.20.0.0/16"
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
    enabled_cluster_log_types                  = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
    
    # OIDC Configuration
    oidc_thumbprint = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
    
    # Enable Features
    create_node_group       = true
    create_service_accounts = true
    enable_eks_pia         = true
    
    # EKS Add-ons Configuration
    eks_addons = {
      # Core Add-ons
      enable_vpc_cni        = true
      enable_kube_proxy     = true
      enable_coredns        = true
      enable_metrics_server = true
      
      vpc_cni_version        = "v1.18.0-eksbuild.1"
      kube_proxy_version     = "v1.32.0-eksbuild.2"
      coredns_version        = "v1.11.1-eksbuild.9"
      metrics_server_version = "v0.7.2-eksbuild.1"
      
      # Storage
      enable_ebs_csi_driver       = true
      ebs_csi_driver_version      = "v1.36.0-eksbuild.1"
      ebs_csi_driver_role_key     = "ebs-csi-driver"
      
      # Secrets Management
      enable_secrets_manager_csi_driver               = true
      secrets_manager_csi_driver_aws_provider_version = "0.3.9"
      enableSecretRotation                            = true
      rotationPollInterval                            = "120s"
      
      # Observability
      enable_cloudwatch_observability       = true
      cloudwatch_observability_version      = "v2.3.0-eksbuild.1"
      cloudwatch_observability_role_key     = "cloudwatch-observability"
      
      # Load Balancer Controller
      enable_aws_load_balancer_controller      = true
      aws_load_balancer_controller_version     = "1.8.1"
      aws_load_balancer_controller_role_key    = "aws-lb-controller"
      
      # Pod Identity Agent
      enable_pod_identity_agent   = true
      pod_identity_agent_version  = "v1.3.4-eksbuild.1"
      
      # Private CA
      enable_privateca_issuer   = true
      privateca_issuer_version  = "v1.3.1-eksbuild.1"
    }

    # Access Entries
    access_entries = {
      cluster_admin = {
        principal_arns = [
          "arn:aws:iam::${local.account_id}:role/ClusterAdminRole"
        ]
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      }
      namespace_admin = {
        principal_arns = [
          "arn:aws:iam::${local.account_id}:role/NamespaceAdminRole"
        ]
        policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
      }
    }

    # IAM Roles for Service Accounts
    iam_roles = {
      aws-lb-controller = {
        key                        = "aws-lb-controller"
        name                       = "eks-aws-load-balancer-controller"
        description                = "IAM role for AWS Load Balancer Controller"
        service_account_namespace  = "kube-system"
        service_account_name       = "aws-load-balancer-controller"
        managed_policy_arns = [
          "arn:aws:iam::${local.account_id}:policy/AWSLoadBalancerControllerIAMPolicy"
        ]
      }
      
      ebs-csi-driver = {
        key                        = "ebs-csi-driver"
        name                       = "eks-ebs-csi-driver"
        description                = "IAM role for EBS CSI Driver"
        service_account_namespace  = "kube-system"
        service_account_name       = "ebs-csi-controller-sa"
        managed_policy_arns = [
          "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        ]
      }
      
      cloudwatch-observability = {
        key                        = "cloudwatch-observability"
        name                       = "eks-cloudwatch-observability"
        description                = "IAM role for CloudWatch Observability"
        service_account_namespace  = "amazon-cloudwatch"
        service_account_name       = "cloudwatch-agent"
        managed_policy_arns = [
          "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
          "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
        ]
      }
    }

    # Service Accounts
    service_accounts = [
      {
        key       = "aws-lb-controller"
        name      = "aws-load-balancer-controller"
        namespace = "kube-system"
        role_key  = "aws-lb-controller"
      }
    ]

    # Pod Identity Associations
    eks_pia = [
      {
        key                       = "aws-lb-controller"
        service_account_namespace = "kube-system"
        service_account_name      = "aws-load-balancer-controller"
        role_key                  = "aws-lb-controller"
      }
    ]

    # Security Groups
    security_groups = [{
      key         = "node-additional"
      name        = "eks-node-additional-sg"
      description = "Additional security group for EKS nodes"
      vpc_name    = "main"
      
      security_group_ingress_rules = [{
        description = "Allow internal communication"
        from_port   = 0
        to_port     = 65535
        protocol    = "-1"
        cidr_blocks = ["10.0.0.0/8"]
      }]
      
      security_group_egress_rules = [{
        description = "Allow all outbound"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }]
    }]

    # Key Pair Configuration
    key_pair = {
      name               = "prod-eks-nodes"
      secret_name        = "prod-eks-nodes-private-key"
      secret_description = "Private key for production EKS node groups"
    }

    # Launch Templates
    launch_templates = [
      {
        key           = "general"
        name          = "general-purpose-nodes"
        instance_type = "t3.large"
        
        vpc_security_group_keys = ["eks_cluster_sg_id", "node-additional"]
        
        block_device_mappings = [{
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 100
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            delete_on_termination = true
            encrypted             = true
          }
        }]
        
        metadata_options = {
          http_endpoint               = "enabled"
          http_tokens                 = "required"
          http_put_response_hop_limit = 2
        }
      },
      {
        key           = "compute"
        name          = "compute-optimized-nodes"
        instance_type = "c5.2xlarge"
        
        vpc_security_group_keys = ["eks_cluster_sg_id"]
        
        block_device_mappings = [{
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 150
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 125
            delete_on_termination = true
            encrypted             = true
          }
        }]
      }
    ]

    # Node Groups
    eks_node_groups = [
      {
        key                  = "general"
        name                 = "general-purpose"
        launch_template_key  = "general"
        
        scaling_config = {
          desired_size = 3
          max_size     = 10
          min_size     = 2
        }
        
        update_config = {
          max_unavailable = 1
        }
        
        labels = {
          "workload-type" = "general"
          "environment"   = "production"
        }
        
        taints = []
      },
      {
        key                  = "compute"
        name                 = "compute-optimized"
        launch_template_key  = "compute"
        
        scaling_config = {
          desired_size = 2
          max_size     = 5
          min_size     = 1
        }
        
        update_config = {
          max_unavailable = 1
        }
        
        labels = {
          "workload-type" = "compute"
          "environment"   = "production"
        }
        
        taints = [{
          key    = "compute-intensive"
          value  = "true"
          effect = "NoSchedule"
        }]
      }
    ]
  }
}
```

---

## IAM Role for Load Balancer Controller

### Manual IAM Policy Creation

Create a file `alb-controller-policy.json`:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": "elasticloadbalancing.amazonaws.com"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeAccountAttributes",
                "ec2:DescribeAddresses",
                "ec2:DescribeAvailabilityZones",
                "ec2:DescribeInternetGateways",
                "ec2:DescribeVpcs",
                "ec2:DescribeVpcPeeringConnections",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeInstances",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeTags",
                "ec2:GetCoipPoolUsage",
                "ec2:DescribeCoipPools",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeLoadBalancerAttributes",
                "elasticloadbalancing:DescribeListeners",
                "elasticloadbalancing:DescribeListenerCertificates",
                "elasticloadbalancing:DescribeSSLPolicies",
                "elasticloadbalancing:DescribeRules",
                "elasticloadbalancing:DescribeTargetGroups",
                "elasticloadbalancing:DescribeTargetGroupAttributes",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:DescribeTags"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cognito-idp:DescribeUserPoolClient",
                "acm:ListCertificates",
                "acm:DescribeCertificate",
                "iam:ListServerCertificates",
                "iam:GetServerCertificate",
                "waf-regional:GetWebACL",
                "waf-regional:GetWebACLForResource",
                "waf-regional:AssociateWebACL",
                "waf-regional:DisassociateWebACL",
                "wafv2:GetWebACL",
                "wafv2:GetWebACLForResource",
                "wafv2:AssociateWebACL",
                "wafv2:DisassociateWebACL",
                "shield:GetSubscriptionState",
                "shield:DescribeProtection",
                "shield:CreateProtection",
                "shield:DeleteProtection"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateSecurityGroup"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "StringEquals": {
                    "ec2:CreateAction": "CreateSecurityGroup"
                },
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags",
                "ec2:DeleteTags"
            ],
            "Resource": "arn:aws:ec2:*:*:security-group/*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:RevokeSecurityGroupIngress",
                "ec2:DeleteSecurityGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateLoadBalancer",
                "elasticloadbalancing:CreateTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:CreateListener",
                "elasticloadbalancing:DeleteListener",
                "elasticloadbalancing:CreateRule",
                "elasticloadbalancing:DeleteRule"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
            ],
            "Condition": {
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags",
                "elasticloadbalancing:RemoveTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
                "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:ModifyLoadBalancerAttributes",
                "elasticloadbalancing:SetIpAddressType",
                "elasticloadbalancing:SetSecurityGroups",
                "elasticloadbalancing:SetSubnets",
                "elasticloadbalancing:DeleteLoadBalancer",
                "elasticloadbalancing:ModifyTargetGroup",
                "elasticloadbalancing:ModifyTargetGroupAttributes",
                "elasticloadbalancing:DeleteTargetGroup"
            ],
            "Resource": "*",
            "Condition": {
                "Null": {
                    "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:AddTags"
            ],
            "Resource": [
                "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
                "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
            ],
            "Condition": {
                "StringEquals": {
                    "elasticloadbalancing:CreateAction": [
                        "CreateTargetGroup",
                        "CreateLoadBalancer"
                    ]
                },
                "Null": {
                    "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:RegisterTargets",
                "elasticloadbalancing:DeregisterTargets"
            ],
            "Resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:SetWebAcl",
                "elasticloadbalancing:ModifyListener",
                "elasticloadbalancing:AddListenerCertificates",
                "elasticloadbalancing:RemoveListenerCertificates",
                "elasticloadbalancing:ModifyRule"
            ],
            "Resource": "*"
        }
    ]
}
```

Create the policy:
```bash
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://alb-controller-policy.json
```

---

## Usage Tips

### 1. Verify Load Balancer Controller Installation

After applying, verify the controller is running:

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### 2. Check Service Account

```bash
kubectl describe sa aws-load-balancer-controller -n kube-system
```

### 3. Test with Sample Ingress

Create a test ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
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
                name: example-service
                port:
                  number: 80
```

### 4. View Outputs

Access the Terragrunt outputs:

```bash
terragrunt output helm_aws_load_balancer_controller
```

---

## Troubleshooting

### Controller Not Starting

1. Check logs:
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

2. Verify IAM role:
```bash
kubectl describe sa aws-load-balancer-controller -n kube-system
```

3. Check IRSA configuration:
```bash
aws iam get-role --role-name eks-aws-load-balancer-controller
```

### ALB Not Created

1. Check controller logs for errors
2. Verify subnet tags:
   - Public subnets: `kubernetes.io/role/elb = 1`
   - Private subnets: `kubernetes.io/role/internal-elb = 1`

3. Ensure VPC ID is correctly configured in the module

---

## Additional Resources

- [AWS Load Balancer Controller Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/docs/)
