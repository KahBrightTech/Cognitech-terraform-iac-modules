variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "web-app"
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "dev-team"
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
  default     = "development"
}