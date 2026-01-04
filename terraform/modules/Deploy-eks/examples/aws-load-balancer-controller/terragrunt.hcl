# AWS Load Balancer Controller Terragrunt Configuration
# This configuration deploys the AWS Load Balancer Controller to an existing EKS cluster

terraform {
  source = "../../"
}

include "root" {
  path = find_in_parent_folders()
}

# Dependencies - adjust paths as needed
dependency "eks" {
  config_path = "../eks-cluster"
  
  # Mock outputs for plan/validate
  mock_outputs = {
    cluster_name     = "mock-cluster"
    cluster_endpoint = "https://mock-endpoint.eks.amazonaws.com"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/MOCK"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

dependency "vpc" {
  config_path = "../vpc"
  
  mock_outputs = {
    vpc_id             = "vpc-mock123"
    private_subnet_ids = ["subnet-mock1", "subnet-mock2", "subnet-mock3"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
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
    key      = "lb-controller"
    name     = dependency.eks.outputs.cluster_name
    role_arn = dependency.eks.outputs.cluster_role_arn
    
    # Network Configuration
    subnet_ids              = dependency.vpc.outputs.private_subnet_ids
    vpc_id                  = dependency.vpc.outputs.vpc_id
    endpoint_private_access = true
    endpoint_public_access  = true
    
    # Cluster Configuration
    version                                     = "1.32"
    oidc_thumbprint                            = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false
    
    # Enable only what's needed for Load Balancer Controller
    create_node_group       = true  # Required for Helm to deploy
    create_service_accounts = true  # Required for IRSA
    
    # AWS Load Balancer Controller Configuration
    eks_addons = {
      # Enable only the Load Balancer Controller
      enable_aws_load_balancer_controller      = true
      aws_load_balancer_controller_version     = "1.8.1"
      aws_load_balancer_controller_role_key    = "aws-lb-controller"
      
      # You may also want to enable these core addons if not already present
      enable_vpc_cni    = false
      enable_kube_proxy = false
      enable_coredns    = false
    }

    # IAM Role for AWS Load Balancer Controller
    iam_roles = {
      aws-lb-controller = {
        key                        = "aws-lb-controller"
        name                       = "${local.common.account_name}-${local.common.region_prefix}-eks-aws-lb-controller"
        description                = "IAM role for AWS Load Balancer Controller with IRSA"
        service_account_namespace  = "kube-system"
        service_account_name       = "aws-load-balancer-controller"
        
        # Attach the AWS Load Balancer Controller IAM Policy
        # Make sure this policy exists in your AWS account
        managed_policy_arns = [
          "arn:aws:iam::${local.account_id}:policy/AWSLoadBalancerControllerIAMPolicy"
        ]
      }
    }

    # Service Account for Load Balancer Controller
    service_accounts = [
      {
        key       = "aws-lb-controller"
        name      = "aws-load-balancer-controller"
        namespace = "kube-system"
        role_key  = "aws-lb-controller"
      }
    ]

    # Access entries (optional - adjust based on your needs)
    access_entries = {}

    # Key pair configuration (required if create_node_group is true)
    key_pair = {
      name               = "${local.common.account_name}-${local.common.region_prefix}-lb-controller-keypair"
      secret_name        = "lb-controller-keypair"
      secret_description = "SSH key pair for Load Balancer Controller node group"
    }

    # Minimal node group configuration (if needed)
    launch_templates = [{
      key           = "minimal"
      name          = "lb-controller-minimal"
      instance_type = "t3.small"
      
      vpc_security_group_keys = ["eks_cluster_sg_id"]
      
      block_device_mappings = [{
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 30
          volume_type           = "gp3"
          delete_on_termination = true
          encrypted             = true
        }
      }]
    }]

    eks_node_groups = [{
      key                  = "minimal"
      name                 = "lb-controller-minimal"
      launch_template_key  = "minimal"
      
      scaling_config = {
        desired_size = 1
        max_size     = 2
        min_size     = 1
      }
      
      update_config = {
        max_unavailable = 1
      }
    }]
  }
}
