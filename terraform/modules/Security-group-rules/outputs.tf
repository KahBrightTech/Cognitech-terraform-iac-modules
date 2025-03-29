output "egress_rules" {
  description = "The egress rules applied to the security group"
  value = var.security_group.egress_rules != null ? {
    for key, item in aws_vpc_security_group_egress_rule.egress :
    key => {
      id                           = item.id
      arn                          = item.arn
      from_port                    = item.from_port
      to_port                      = item.to_port
      ip_protocol                  = item.ip_protocol
      referenced_security_group_id = item.referenced_security_group_id
    }
  } : null
}


output "ingress_rules" {
  description = "The ingress rules applied to the security group"
  value = var.security_group.ingress_rules != null ? {
    for key, item in aws_vpc_security_group_ingress_rule.ingress :
    key => {
      id                           = item.id
      arn                          = item.arn
      from_port                    = item.from_port
      to_port                      = item.to_port
      ip_protocol                  = item.ip_protocol
      referenced_security_group_id = item.referenced_security_group_id
    }
  } : null
}

output "security_group_id" {
  description = "The security group id for the rules"
  value       = var.security_group.security_group_id

}
