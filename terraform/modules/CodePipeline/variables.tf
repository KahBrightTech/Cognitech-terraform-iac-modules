variable "common" {
  description = "Common variables used by all resources"
  type = object({
    global           = bool
    tags             = map(string)
    account_name     = string
    region_prefix    = string
    account_name_abr = optional(string, "")
  })
}

#--------------------------------------------------------------------
# CodePipeline Variable
#--------------------------------------------------------------------
variable "codepipeline" {
  description = "CodePipeline configuration"
  default     = null
  type = object({
    artifact_bucket_name = string
    pipelines = list(object({
      name                  = string
      ecr_repository_name   = string
      ecr_image_tag         = string
      ecs_cluster_name      = string
      ecs_service_name      = string
      listener_arns         = list(string)
      target_group_1_name   = string
      target_group_2_name   = string
      deployment_config     = optional(string)
      termination_wait_time = optional(number)
    }))
  })
}
