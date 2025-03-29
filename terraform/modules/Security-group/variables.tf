variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "security_group" {
  description = "The vpc security group"
  type = object({
    name        = string
    vpc_id      = string
    description = string
  })

}

variable "bypass" {
  description = "Bypass the creation of the security group"
  type        = bool
  default     = false

}
