#--------------------------------------------------------------------
# TGW Route - Creates transit gateway attachment
#--------------------------------------------------------------------
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_attachment" {
  subnet_ids         = var.tgw_attachments.subnet_ids
  transit_gateway_id = var.tgw_attachments.transit_gateway_id
  vpc_id             = var.vpc_id
  tags = merge(var.common.tags,
    {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.tgw_attachments.name}"
    }
  )
}

#--------------------------------------------------------------------
# Creates RAM Resource Share (if enabled)
#--------------------------------------------------------------------
resource "aws_ram_resource_share" "main" {
  count = var.tgw_attachments.ram != null ? (var.tgw_attachments.ram.enabled ? 1 : 0) : 0

  name                      = var.tgw_attachments.ram.share_name
  allow_external_principals = var.tgw_attachments.ram.allow_external_principals

  tags = merge(
    var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.tgw_attachments.ram.share_name}"
  })
}

#--------------------------------------------------------------------
# Creates RAM Principal Associations (for each principal)
#--------------------------------------------------------------------
resource "aws_ram_principal_association" "main" {
  count = var.tgw_attachments.ram != null ? (var.tgw_attachments.ram.enabled && length(var.tgw_attachments.ram.principals) > 0 ? length(var.tgw_attachments.ram.principals) : 0) : 0

  principal          = var.tgw_attachments.ram.principals[count.index]
  resource_share_arn = aws_ram_resource_share.main[0].arn

  depends_on = [aws_ram_resource_share.main]
}

#--------------------------------------------------------------------
# Creates RAM Resource Associations (associates the TGW attachment)
#--------------------------------------------------------------------
resource "aws_ram_resource_association" "main" {
  count = var.tgw_attachments.ram != null ? (var.tgw_attachments.ram.enabled ? 1 : 0) : 0

  resource_arn       = aws_ec2_transit_gateway_vpc_attachment.vpc_attachment.arn
  resource_share_arn = aws_ram_resource_share.main[0].arn

  depends_on = [aws_ram_resource_share.main, aws_ec2_transit_gateway_vpc_attachment.vpc_attachment]
}







