#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#--------------------------------------------------------------------
# Kubernetes Service Account
#--------------------------------------------------------------------
resource "kubernetes_service_account" "irsa" {
  metadata {
    name      = "${var.common.account_name}-${var.common.region_prefix}-${var.eks_service_account.name}-sa"
    namespace = coalesce(var.eks_service_account.namespace, "default")
    annotations = {
      "eks.amazonaws.com/role-arn" = var.eks_service_account.role_arn
    }
  }
}
