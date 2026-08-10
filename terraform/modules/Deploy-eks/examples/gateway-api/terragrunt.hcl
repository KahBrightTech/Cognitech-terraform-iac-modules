# Gateway API Terragrunt Configuration
# This example deploys NGINX Gateway Fabric with an AWS Network Load Balancer through the Deploy-eks module.
# Note: Gateway API CRDs must already exist in the cluster before this controller is installed.

terraform {
  source = "../../"
}

include "root" {
  path = find_in_parent_folders()
}

# Dependencies - adjust paths as needed
dependency "eks" {
  config_path = "../eks-cluster"

  mock_outputs = {
    cluster_name      = "mock-cluster"
    cluster_role_arn  = "arn:aws:iam::123456789012:role/mock-eks-cluster-role"
    cluster_endpoint  = "https://mock-endpoint.eks.amazonaws.com"
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
}

inputs = {
  common = local.common

  eks = {
    key      = "gateway-api"
    name     = dependency.eks.outputs.cluster_name
    role_arn = dependency.eks.outputs.cluster_role_arn

    # Cluster network configuration
    subnet_ids              = dependency.vpc.outputs.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true

    # Cluster configuration
    version                                     = "1.32"
    oidc_thumbprint                             = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false

    # Required for Helm-based controllers
    create_node_group       = true
    create_service_accounts = true

    eks_addons = {
      enable_aws_load_balancer_controller   = true
      aws_load_balancer_controller_version  = "1.8.1"
      aws_load_balancer_controller_role_key = "aws-lb-controller"
      enable_ingress                        = true

      ingress = {
        type = "gateway_api"

        gateway_api = {
          version            = "2.6.7"
          release_name       = "ngf"
          namespace          = "nginx-gateway"
          gateway_class_name = "nginx"
          controller_name    = "gateway.nginx.org/nginx-gateway-controller"
          fabric_replicas    = 1
          nginx_replicas     = 2

          # These values are AWS IDs, not names.
          nlb_name            = "example-gateway-api-nlb"
          subnet_ids          = dependency.vpc.outputs.private_subnet_ids
          security_group_keys = ["gateway-api-nlb"]

          service_annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
          }

          values = [
            {
              nginxGateway = {
                watchNamespaces = ["default", "apps"]
              }
            }
          ]
        }
      }

      # Enable these only if this stack is also responsible for them.
      enable_vpc_cni    = false
      enable_kube_proxy = false
      enable_coredns    = false
    }

    iam_roles = {
      aws-lb-controller = {
        key                       = "aws-lb-controller"
        name                      = "${local.common.account_name}-${local.common.region_prefix}-eks-aws-lb-controller"
        description               = "IAM role for AWS Load Balancer Controller with IRSA"
        service_account_namespace = "kube-system"
        service_account_name      = "aws-load-balancer-controller"
        managed_policy_arns = [
          "arn:aws:iam::${local.account_id}:policy/AWSLoadBalancerControllerIAMPolicy"
        ]
      }
    }

    service_accounts = [
      {
        key       = "aws-lb-controller"
        name      = "aws-load-balancer-controller"
        namespace = "kube-system"
        role_key  = "aws-lb-controller"
      }
    ]

    access_entries = {}

    key_pair = {
      name               = "${local.common.account_name}-${local.common.region_prefix}-gateway-api-keypair"
      secret_name        = "gateway-api-keypair"
      secret_description = "SSH key pair for the Gateway API example node group"
    }

    security_groups = [
      {
        key         = "gateway-api-nlb"
        name        = "gateway-api-nlb"
        description = "Security group attached to the Gateway API NLB"
        vpc_id      = dependency.vpc.outputs.vpc_id
        vpc_name    = "shared"
        security_group_ingress_rules = [
          {
            description = "Allow HTTP from the internet"
            from_port   = 80
            to_port     = 80
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
          },
          {
            description = "Allow HTTPS from the internet"
            from_port   = 443
            to_port     = 443
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
          }
        ]
        security_group_egress_rules = [
          {
            description = "Allow all outbound traffic"
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
        ]
      }
    ]

    launch_templates = [{
      key           = "gateway"
      name          = "gateway-api"
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
      key                 = "gateway"
      name                = "gateway-api"
      launch_template_key = "gateway"

      scaling_config = {
        desired_size = 2
        max_size     = 3
        min_size     = 1
      }

      update_config = {
        max_unavailable = 1
      }
    }]
  }
}
