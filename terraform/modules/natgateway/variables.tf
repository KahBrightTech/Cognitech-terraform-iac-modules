variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "ngw" {
  description = "The nat gateway to be associated to the private subnet"
  type = object({
    name          = string
    subnet_id     = list(string)
    allocation_id = string
  })
}


