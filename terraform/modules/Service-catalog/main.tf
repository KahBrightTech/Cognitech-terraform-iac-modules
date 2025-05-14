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


resource "aws_servicecatalog_portfolio_product_association" "assoc" {
  portfolio_id = aws_servicecatalog_portfolio.portfolio.id
  product_id   = aws_servicecatalog_product.product.id
}



