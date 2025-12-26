#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
#--------------------------------------------------------------------
# EKS Application Add-ons (Requires nodes to be available)
#--------------------------------------------------------------------

resource "aws_eks_addon" "coredns" {
  cluster_name                = var.eks_addons.cluster_name
  addon_name                  = "coredns"
  addon_version               = var.eks_addons.coredns_version
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_cluster.name}-coredns-addon"
  })
}

resource "aws_eks_addon" "metrics_server" {
  cluster_name                = var.eks_addons.cluster_name
  addon_name                  = "metrics-server"
  addon_version               = var.eks_addons.metrics_server_version
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_addons.cluster_name}-metrics-server-addon"
  })
}

resource "aws_eks_addon" "cloudwatch_observability" {
  count                       = contains(var.eks_addons.addon_names, "amazon-cloudwatch-observability") && var.eks_addons.create_cw_role ? 1 : 0
  cluster_name                = var.eks_addons.cluster_name
  addon_name                  = "amazon-cloudwatch-observability"
  addon_version               = var.eks_addons.cloudwatch_observability_version
  resolve_conflicts_on_update = "PRESERVE"
  service_account_role_arn    = var.eks_addons.create_cw_role && var.eks_addons.cloudwatch_observability_role_arn != null ? var.eks_addons.cloudwatch_observability_role_arn : null

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_addons.cluster_name}-cloudwatch-observability-addon"
  })
}

resource "aws_eks_addon" "secrets_manager_csi_driver" {
  cluster_name                = var.eks_addons.cluster_name
  addon_name                  = "aws-secrets-store-csi-driver-provider"
  addon_version               = var.eks_addons.secrets_manager_csi_driver_version
  resolve_conflicts_on_update = "PRESERVE"
  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_addons.cluster_name}-secrets-manager-csi-driver-addon"
  })
}
