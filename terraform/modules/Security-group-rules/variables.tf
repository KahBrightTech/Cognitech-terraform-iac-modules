variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "security_group_rules" {
  description = "The vpc security group rules"
  type = object({
    name              = string
    security_group_id = string # This will be the ID of the security group created
    type              = string # e.g., "ingress" or "egress"
    protocol          = string # e.g., "tcp", "udp", "icmp", or "-1" for all protocols
    from_port         = number # e.g., 80 for HTTP, 443 for HTTPS, or 0 for all ports
    to_port           = number # e.g., 80 for HTTP, 443 for HTTPS, or 0 for all ports
    cidr_blocks       = list(string)
    description       = string # Description of the rule
  })
  default = null
}

variable "bypass" {
  description = "Bypass the creation of the security group"
  type        = bool
  default     = false

}
