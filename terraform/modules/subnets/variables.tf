variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "subnets" {
  description = "The private subnet variables"
  type = list(object({
    private_subnet_name       = string
    private_subnet_cidr_block = list(string)
    az                        = list(string)
    public_subnet_name        = string
    public_subnet_cidr_block  = list(string)
  }))
}

variable "vpc_id" {
  description = "The vpc id"
  type        = string
}
