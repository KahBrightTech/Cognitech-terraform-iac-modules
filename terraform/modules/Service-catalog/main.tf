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
  name        = var.service_catalog.products.name
  owner       = var.service_catalog.products.owner
  type        = var.service_catalog.product.type #CLOUD_FORMATION_TEMPLATE
  description = var.service_catalog.products.description
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.service_catalog.products.name}-product"
    }
  )

  provisioning_artifact_parameters {
    name         = var.service_catalog.provisioning_artifact_parameters.name
    description  = var.service_catalog.provisioning_artifact_parameters.description
    type         = var.service_catalog.provisioning_artifact_parameters.type #CLOUD_FORMATION_TEMPLATE
    template_url = var.service_catalog.provisioning_artifact_parameters.template_url
  }
}

resource "aws_servicecatalog_portfolio_product_association" "assoc" {
  portfolio_id = aws_servicecatalog_portfolio.portfolio.id
  product_id   = aws_servicecatalog_product.product.id
}



