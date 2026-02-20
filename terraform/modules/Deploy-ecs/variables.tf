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

variable "ecs" {
  description = "ECS configuration including common settings"
  type = object({
    cluster_name               = string
    container_insights_enabled = optional(bool, false)
    load_balancer_arn          = optional(string)
    target_group_arns          = optional(list(string), [])
    execute_command_configuration = optional(object({
      kms_key_id = optional(string)
      logging    = optional(string, "DEFAULT")
      log_configuration = optional(object({
        cloud_watch_encryption_enabled = optional(bool, false)
        cloud_watch_log_group_name     = optional(string)
        s3_bucket_name                 = optional(string)
        s3_bucket_encryption_enabled   = optional(bool, false)
        s3_key_prefix                  = optional(string)
      }))
    }))
    capacity_providers = optional(object({
      capacity_provider_names = list(string)
      default_capacity_provider_strategy = optional(list(object({
        capacity_provider = string
        weight            = optional(number, 1)
        base              = optional(number, 0)
      })))
    }))
    task_definitions = optional(list(object({
      family                     = string
      task_role_arn              = optional(string)
      execution_role_arn         = optional(string)
      network_mode               = optional(string, "bridge")
      requires_compatibilities   = optional(list(string), ["EC2"])
      cpu                        = optional(string)
      memory                     = optional(string)
      container_definitions      = optional(string)
      container_definitions_file = optional(string)
      volumes = optional(list(object({
        name      = string
        host_path = optional(string)

        docker_volume_configuration = optional(object({
          scope         = optional(string)
          autoprovision = optional(bool)
          driver        = optional(string)
          driver_opts   = optional(map(string))
          labels        = optional(map(string))
        }))
        efs_volume_configuration = optional(object({
          file_system_id          = string
          root_directory          = optional(string, "/")
          transit_encryption      = optional(string, "DISABLED")
          transit_encryption_port = optional(number)
          authorization_config = optional(object({
            access_point_id = optional(string)
            iam             = optional(string)
          }))
        }))
      })))
      placement_constraints = optional(list(object({
        type       = string
        expression = optional(string)
      })))

      proxy_configuration = optional(object({
        container_name = string
        properties     = optional(map(string))
        type           = optional(string, "APPMESH")
      }))
      runtime_platform = optional(object({
        operating_system_family = optional(string, "LINUX")
        cpu_architecture        = optional(string, "X86_64")
      }))
    })))
    services = optional(list(object({
      name                               = string
      task_definition                    = optional(string)
      task_definition_family             = optional(string)
      desired_count                      = optional(number, 1)
      launch_type                        = optional(string, "EC2")
      platform_version                   = optional(string)
      scheduling_strategy                = optional(string, "REPLICA")
      deployment_maximum_percent         = optional(number, 200)
      deployment_minimum_healthy_percent = optional(number, 100)
      enable_ecs_managed_tags            = optional(bool, false)
      enable_execute_command             = optional(bool, false)
      health_check_grace_period_seconds  = optional(number)
      propagate_tags                     = optional(string)
      capacity_provider_strategy = optional(list(object({
        capacity_provider = string
        weight            = optional(number, 1)
        base              = optional(number, 0)
      })))
      deployment_circuit_breaker = optional(object({
        enable   = bool
        rollback = bool
      }))
      deployment_controller = optional(object({
        type = optional(string, "ECS")
      }))
      load_balancers = optional(list(object({
        target_group_arn = string
        container_name   = string
        container_port   = number
      })))
      network_configuration = optional(object({
        subnets          = list(string)
        security_groups  = optional(list(string))
        assign_public_ip = optional(bool, false)
      }))
      placement_constraints = optional(list(object({
        type       = string
        expression = optional(string)
      })))
      ordered_placement_strategy = optional(list(object({
        type  = string
        field = optional(string)
      })))
      service_registries = optional(object({
        registry_arn   = string
        port           = optional(number)
        container_name = optional(string)
        container_port = optional(number)
      }))
    })))
    ec2_autoscaling = optional(list(object({
      launch_templates = optional(list(object({
        key              = optional(string)
        name             = optional(string)
        instance_profile = optional(string)
        custom_ami       = optional(string)
        ami_config = object({
          os_release_date  = optional(string)
          os_base_packages = optional(string)
        })
        instance_type               = optional(string)
        key_name                    = optional(string)
        ec2_ssh_key                 = optional(string)
        associate_public_ip_address = optional(bool)
        vpc_security_group_ids      = optional(list(string))
        vpc_security_group_keys     = optional(list(string))
        tags                        = optional(map(string))
        user_data                   = optional(string)
        volume_size                 = optional(number)
        root_device_name            = optional(string)
      })))
      autoscaling_group = optional(list(object({
        name                      = optional(string)
        min_size                  = optional(number)
        max_size                  = optional(number)
        health_check_type         = optional(string)
        health_check_grace_period = optional(number)
        force_delete              = optional(bool)
        desired_capacity          = optional(number)
        subnet_ids                = optional(list(string))
        attach_target_groups      = optional(list(string))
        launch_template = optional(object({
          id      = string
          version = optional(string, "$Latest")
        }))
        timeouts = optional(object({
          delete = optional(string)
        }))
        tags = optional(map(string))
        additional_tags = optional(list(object({
          key                 = string
          value               = string
          propagate_at_launch = optional(bool, true)
        })))
      })))
      capacity_provider = object({
        name                           = string
        managed_termination_protection = optional(string, "DISABLED")
        managed_scaling = object({
          maximum_scaling_step_size = optional(number, 10)
          minimum_scaling_step_size = optional(number, 1)
          status                    = optional(string, "ENABLED")
          target_capacity           = optional(number, 100)
          instance_warmup_period    = optional(number, 300)
        })
      })
      scaling_policies = optional(object({
        scale_up = object({
          scaling_adjustment = number
          adjustment_type    = optional(string, "ChangeInCapacity")
          cooldown           = optional(number, 300)
        })
        scale_down = object({
          scaling_adjustment = number
          adjustment_type    = optional(string, "ChangeInCapacity")
          cooldown           = optional(number, 300)
        })
      }))
    })))
  })
  validation {
    condition = alltrue([
      for svc in coalesce(var.ecs.services, []) :
      svc.deployment_controller == null ||
      svc.deployment_controller.type == null ||
      contains(["ECS", "CODE_DEPLOY", "EXTERNAL"], svc.deployment_controller.type)
    ])
    error_message = "The deployment_controller type must be one of: ECS, CODE_DEPLOY, or EXTERNAL."
  }
}
