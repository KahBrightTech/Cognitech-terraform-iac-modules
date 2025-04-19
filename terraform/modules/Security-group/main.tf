#--------------------------------------------------------------------
# Security Group - Create a security group for the VPC
#--------------------------------------------------------------------
resource "aws_security_group" "security_group" {
  name        = "${var.common.account_name}-${var.common.region_prefix}-${var.security_group.name}"
  name_prefix = var.security_group.name_prefix
  description = var.security_group.description
  vpc_id      = var.security_group.vpc_id

  dynamic "egress" {
    for_each = var.security_group.security_group_egress_rules == null ? [] : var.security_group.security_group_egress_rules

    content {
      description     = egress.value["description"]
      from_port       = egress.value["from_port"]
      to_port         = egress.value["to_port"]
      protocol        = egress.value["protocol"]
      cidr_blocks     = egress.value["cidr_blocks"] == null ? null : egress.value["cidr_blocks"]
      security_groups = egress.value["security_groups"] == null ? null : egress.value["security_groups"]
      self            = egress.value["self"] == null ? null : egress.value["self"]
    }
  }

  dynamic "ingress" {
    for_each = var.security_group.security_group_ingress_rules == null ? [] : var.security_group.security_group_ingress_rules

    content {
      description     = ingress.value["description"]
      from_port       = ingress.value["from_port"]
      to_port         = ingress.value["to_port"]
      protocol        = ingress.value["protocol"]
      cidr_blocks     = ingress.value["cidr_blocks"] == null ? null : ingress.value["cidr_blocks"]
      security_groups = ingress.value["security_groups"] == null ? null : ingress.value["security_groups"]
      self            = ingress.value["self"] == null ? null : ingress.value["self"]
    }
  }
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.security_group.name}"
    }
  )
  lifecycle {
    create_before_destroy = true
  }
}


