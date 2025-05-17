
#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_iam_roles" "admin_role" {
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "network_role" {
  name_regex  = "AWSReservedSSO_NetworkAdministrator_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_role" "github_oidc_role" {
  name = "prod-OIDCGitHubRole-role"
}

data "aws_iam_group" "service_catalog_endusers" {
  group_name = "Service-Catalog-Endusers"
}

#--------------------------------------------------------------------
# Creates Service Catalog resources 
#--------------------------------------------------------------------
resource "aws_servicecatalog_portfolio" "portfolio" {
  name          = var.service_catalog.name
  description   = var.service_catalog.description
  provider_name = var.service_catalog.provider_name
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.service_catalog.name}-portfolio"
    }
  )
}

resource "aws_servicecatalog_product" "product" {
  for_each    = { for item in var.service_catalog.products : item.name => item }
  name        = each.value.name
  owner       = each.value.owner
  type        = "CLOUD_FORMATION_TEMPLATE"
  description = each.value.description

  provisioning_artifact_parameters {
    name         = var.service_catalog.provisioning_artifact_parameters[each.key].name
    description  = var.service_catalog.provisioning_artifact_parameters[each.key].description
    type         = var.service_catalog.provisioning_artifact_parameters[each.key].type
    template_url = var.service_catalog.provisioning_artifact_parameters[each.key].template_url
  }
}


resource "aws_servicecatalog_product_portfolio_association" "assoc" {
  for_each     = aws_servicecatalog_product.product
  portfolio_id = aws_servicecatalog_portfolio.portfolio.id
  product_id   = each.value.id
}

resource "aws_servicecatalog_principal_portfolio_association" "admin" {
  count          = var.service_catalog.associate_admin_role ? 1 : 0
  portfolio_id   = aws_servicecatalog_portfolio.portfolio.id
  principal_arn  = tolist(data.aws_iam_roles.admin_role.arns)[0]
  principal_type = "IAM"
}

resource "aws_servicecatalog_principal_portfolio_association" "network" {
  count          = var.service_catalog.associate_network_role ? 1 : 0
  portfolio_id   = aws_servicecatalog_portfolio.portfolio.id
  principal_arn  = tolist(data.aws_iam_roles.network_role.arns)[0]
  principal_type = "IAM"
}

resource "aws_servicecatalog_principal_portfolio_association" "group" {
  count          = var.service_catalog.associate_iam_group ? 1 : 0
  portfolio_id   = aws_servicecatalog_portfolio.portfolio.id
  principal_arn  = data.aws_iam_group.service_catalog_endusers.arn
  principal_type = "IAM"
}




