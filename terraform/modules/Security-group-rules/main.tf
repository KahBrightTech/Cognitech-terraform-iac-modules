#--------------------------------------------------------------------
# Security Group EGRESS rule
#--------------------------------------------------------------------
resource "aws_vpc_security_group_egress_rule" "egress" {
  for_each                     = var.security_group.egress_rules != null ? { for rule in var.securoty_group.egress_rules : rule.key => rule } : {}
  security_group_id            = var.security_group.security_group_id
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  description                  = each.value.description
  from_port                    = each.value.from_port
  ip_protocol                  = each.value.ip_protocol
  to_port                      = each.value.to_port
  referenced_security_group_id = each.value.target_sg_id
}


#--------------------------------------------------------------------
# Security Group INGRESS rule
#--------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "ingress" {
  for_each                     = var.security_group.ingress_rules != null ? { for rule in var.securoty_group.ingress_rules : rule.key => rule } : {}
  security_group_id            = var.security_group.security_group_id
  cidr_ipv4                    = each.value.cidr_ipv4
  cidr_ipv6                    = each.value.cidr_ipv6
  description                  = each.value.description
  from_port                    = each.value.from_port
  ip_protocol                  = each.value.ip_protocol
  to_port                      = each.value.to_port
  referenced_security_group_id = each.value.source_sg_id
}
