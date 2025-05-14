variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global        = bool
    tags          = map(string)
    account_name  = string
    region_prefix = string
  })
}

variable "service_catalog" {
  description = "Service Catalog variables"
  type = object({
    name          = string
    description   = optional(string)
    provider_name = optional(string)
    products = list(object({
      name        = string
      description = optional(string)
      type        = string
      owner       = optional(string)
    }))
    provisioning_artifact_parameters = list(object({
      name         = string
      description  = string
      type         = string
      template_url = string
    }))
  })
  default = null
}

