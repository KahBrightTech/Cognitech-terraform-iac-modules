# Karpenter Example
#
# Deploys an EKS cluster with a minimal static node group (just enough to
# host the Karpenter controller pod itself) and Karpenter enabled to handle
# all further node scaling. See README.md in this folder for the full
# walkthrough, including the two IAM policy files this config references.

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../"
}

locals {
  common_vars  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  common       = local.common_vars.locals.common
  account_id   = get_aws_account_id()
  region       = get_aws_region()
  cluster_name = "my-cluster" # must match what you substitute into karpenter-controller-policy.json
}

inputs = {
  common = local.common

  eks = {
    key                     = "main"
    name                    = local.cluster_name
    role_arn                = "arn:aws:iam::${local.account_id}:role/eks-cluster-role"
    subnet_ids              = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]
    endpoint_private_access = true
    endpoint_public_access  = true
    version                 = "1.32"
    oidc_thumbprint         = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"

    create_node_group       = true # required - hosts the Karpenter controller pod
    create_service_accounts = true # required - Karpenter and its node role both need IRSA

    eks_addons = {
      enable_vpc_cni            = true
      enable_kube_proxy         = true
      enable_coredns            = true
      enable_pod_identity_agent = true

      # Karpenter - NOT enable_cluster_autoscaler; the module will fail plan
      # if both are true, since they'd fight over scaling the same nodes.
      enable_karpenter = true

      # Every controller-type Deployment/DaemonSet the module manages
      # (coredns, csi driver controllers, load balancer controller,
      # karpenter itself, etc.) is pinned to a "system" node group via a
      # fixed nodeSelector/toleration on workload-type=system - see main.tf.
      # Application workloads get no toleration for this taint, so the
      # scheduler can only place them on Karpenter-provisioned nodes.

      karpenter = {
        chart_version           = "1.13.0"
        controller_role_key     = "karpenter_controller"
        node_role_key           = "karpenter_node"
        interruption_queue_name = local.cluster_name
        nodepool_manifest_file  = "${get_terragrunt_dir()}/karpenter-nodepool.yaml"
      }
    }

    # IAM roles Karpenter needs: one for the controller pod (IRSA, trusts
    # the cluster's OIDC provider - the module's default), one for the
    # nodes Karpenter launches (trusts ec2.amazonaws.com - hence the
    # explicit assume_role_policy file, which overrides that default).
    iam_roles = [
      {
        key                       = "karpenter_controller"
        name                      = "karpenter-controller-role"
        service_account_name      = "karpenter"
        service_account_namespace = "kube-system"
        create_custom_policy      = true
        policy = {
          name   = "karpenter-controller-policy"
          policy = "${get_terragrunt_dir()}/karpenter-controller-policy.json"
        }
      },
      {
        key                  = "karpenter_node"
        name                 = "karpenter-node-role"
        assume_role_policy   = "${get_terragrunt_dir()}/karpenter-node-trust-policy.json"
        create_custom_policy = false
        managed_policy_arns = [
          "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
          "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
          "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
          "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        ]
      }
    ]

    # --- Minimal static node group: hosts the Karpenter controller only ---
    key_pair = {
      name        = "${local.cluster_name}-nodes-keypair"
      secret_name = "${local.cluster_name}-nodes-private-key"
    }

    launch_templates = [
      {
        key           = "system"
        name          = "${local.cluster_name}-system"
        instance_type = "t3.medium"

        vpc_security_group_keys = ["eks_cluster_sg_id"]

        ami_config       = {}
        volume_size      = 30
        root_device_name = "/dev/xvda"
      }
    ]

    eks_node_groups = [
      {
        key                 = "system"
        node_group_name     = "system"
        launch_template_key = "system"
        subnet_ids          = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]

        desired_size = 1
        min_size     = 1
        max_size     = 2

        instance_types = ["t3.medium"]
        capacity_type  = "ON_DEMAND"

        # Must match the fixed workload-type=system label/toleration the
        # module applies to controller pods in main.tf.
        labels = {
          "workload-type" = "system"
        }

        # Repels every pod without a matching toleration - i.e. all
        # application workloads - onto Karpenter-provisioned nodes instead.
        # Controller pods get the matching toleration automatically (see
        # local.controller_toleration in main.tf). Note the taint effect
        # here uses the AWS API's NO_SCHEDULE spelling, not Kubernetes' NoSchedule.
        taints = [
          {
            key    = "workload-type"
            value  = "system"
            effect = "NO_SCHEDULE"
          }
        ]
      }
    ]

    access_entries = {
      cluster_admin = {
        principal_arns = ["arn:aws:iam::${local.account_id}:role/AdminRole"]
        policy_arn     = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
      }
    }
  }
}
