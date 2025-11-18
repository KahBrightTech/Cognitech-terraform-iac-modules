# AWS Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

# Project Configuration
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "secure-web-app"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "security-team"
}

variable "team" {
  description = "Team responsible for the resources"
  type        = string
  default     = "platform-security"
}

variable "account_name" {
  description = "AWS account name"
  type        = string
  default     = "mycompany"
}

variable "account_name_abbreviation" {
  description = "AWS account name abbreviation"
  type        = string
  default     = "mc"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "security"
}

variable "compliance_tags" {
  description = "Compliance requirement tags"
  type        = string
  default     = "SOC2,PCI-DSS"
}

# WAF Rule Configuration
variable "core_rule_exclusions" {
  description = "Rules to exclude from AWS Core Rule Set"
  type        = list(string)
  default     = ["SizeRestrictions_BODY", "GenericRFI_BODY"]
}

variable "blocked_countries" {
  description = "List of country codes to block"
  type        = list(string)
  default     = ["CN", "RU", "KP", "IR"]
}

# Rate Limiting Configuration
variable "rate_limit_action" {
  description = "Action to take for rate limiting (block or count)"
  type        = string
  default     = "count"
  validation {
    condition     = contains(["block", "count"], var.rate_limit_action)
    error_message = "Rate limit action must be either block or count."
  }
}

variable "general_rate_limit" {
  description = "General rate limit per IP (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "login_rate_limit" {
  description = "Rate limit for login pages per IP (requests per 5 minutes)"
  type        = number
  default     = 100
}

# IP Configuration
variable "trusted_ip_ranges" {
  description = "List of trusted IP ranges for whitelist"
  type        = list(string)
  default = [
    "203.0.113.0/24",  # Office network
    "198.51.100.0/24", # Partner network
    "192.0.2.0/24"     # Admin network
  ]
}

variable "blocked_ip_ranges" {
  description = "List of IP ranges to block"
  type        = list(string)
  default = [
    "192.0.2.44/32",  # Known malicious IP
    "203.0.113.89/32" # Blocked bot
  ]
}

# ALB Association
variable "associate_with_alb" {
  description = "Whether to associate WAF with an ALB"
  type        = bool
  default     = false
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer to associate with WAF"
  type        = string
  default     = null
  # Example: "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-alb/1234567890abcdef"
}

# Logging Configuration
variable "log_retention_days" {
  description = "Number of days to retain WAF logs in CloudWatch"
  type        = number
  default     = 90
}

variable "log_redacted_fields" {
  description = "List of fields to redact from WAF logs"
  type        = list(string)
  default     = ["uri_path", "query_string", "header_authorization"]
}