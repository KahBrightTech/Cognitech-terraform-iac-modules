#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#--------------------------------------------------------------------
# Creates RAM Share for AWS Resources
#--------------------------------------------------------------------

resource "aws_ram_resource_share" "main" {
  count = var.ram.enabled ? 1 : 0

  name                      = var.ram.share_name
  allow_external_principals = var.ram.allow_external_principals

  tags = merge(var.common.tags, {
    Name = var.ram.share_name
  })
}

#--------------------------------------------------------------------
# Creates RAM Share Associations
#--------------------------------------------------------------------
resource "aws_ram_principal_association" "main" {
  count = var.ram.enabled && length(var.ram.principals) > 0 ? length(var.ram.principals) : 0

  principal          = var.ram.principals[count.index]
  resource_share_arn = aws_ram_resource_share.main[0].arn

  depends_on = [aws_ram_resource_share.main]
}

#--------------------------------------------------------------------
# Creates RAM Resource Associations
#--------------------------------------------------------------------

resource "aws_ram_resource_association" "main" {
  count = var.ram.enabled && length(var.ram.resource_arns) > 0 ? length(var.ram.resource_arns) : 0

  resource_arn       = var.ram.resource_arns[count.index]
  resource_share_arn = aws_ram_resource_share.main[0].arn

  depends_on = [aws_ram_resource_share.main]
}

