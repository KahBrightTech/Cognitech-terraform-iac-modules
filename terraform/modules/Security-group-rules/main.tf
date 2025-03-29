#--------------------------------------------------------------------
# Security Group rules - Create a security group rules
#--------------------------------------------------------------------
resource "aws_security_group_rules" "security_group_rules" {
  count             = var.bypass == false ? 1 : 0
  security_group_id = var.security_group.rules.security_group_id
  type              = var.security_group_rules.type        # e.g., "ingress" or "egress"
  protocol          = var.security_group_rules.protocol    # e.g., "tcp", "udp", "icmp", or "-1" for all protocols
  from_port         = var.security_group_rules.from_port   # e.g., 80 for HTTP, 443 for HTTPS, or 0 for all ports
  to_port           = var.security_group_rules.to_port     # e.g., 80 for HTTP, 443 for HTTPS, or 0 for all ports
  cidr_blocks       = var.security_group_rules.cidr_blocks # List of CIDR blocks for the rule
  description       = var.security_group_rules.description # Description of the rule
}


