#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
#--------------------------------------------------------------------
# EKS Application Add-ons (Requires nodes to be available)
#--------------------------------------------------------------------

resource "aws_eks_addon" "coredns" {
  count                       = var.var.eks_addons.addon_names == "coredns" ? 1 : 0
  cluster_name                = var.eks_addons.cluster_name
  addon_name                  = "coredns"
  addon_version               = var.eks_addons.coredns_version
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_addons.cluster_key}-coredns-addon"
  })
}

resource "aws_eks_addon" "metrics_server" {
  count                       = var.var.eks_addons.addon_names == "metrics-server" ? 1 : 0
  cluster_name                = var.eks_addons.cluster_name
  addon_name                  = "metrics-server"
  addon_version               = var.eks_addons.metrics_server_version
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_addons.cluster_key}-metrics-server-addon"
  })
}

resource "aws_eks_addon" "cloudwatch_observability" {
  count                       = var.var.eks_addons.addon_names == "amazon-cloudwatch-observability" && var.eks_addons.create_cw_role ? 1 : 0
  cluster_name                = var.eks_addons.cluster_name
  addon_name                  = "amazon-cloudwatch-observability"
  addon_version               = var.eks_addons.cloudwatch_observability_version
  resolve_conflicts_on_update = "PRESERVE"
  service_account_role_arn    = var.eks_addons.cloudwatch_observability_role_arn

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_addons.cluster_key}-cloudwatch-observability-addon"
  })
}

resource "aws_eks_addon" "secrets_manager_csi_driver" {
  count                       = var.var.eks_addons.addon_names == "aws-secrets-store-csi-driver-provider" ? 1 : 0
  cluster_name                = var.eks_addons.cluster_name
  addon_name                  = "aws-secrets-store-csi-driver-provider"
  addon_version               = var.eks_addons.secrets_manager_csi_driver_version
  resolve_conflicts_on_update = "PRESERVE"
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_addons.cluster_key}-secrets-manager-csi-driver-addon"
  })
}
