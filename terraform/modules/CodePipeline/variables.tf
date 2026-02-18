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
  description = "ECS configuration"
  type = object({
    cluster_name               = string
    container_insights_enabled = optional(bool, false)

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

    task_definition = optional(object({
      family                   = string
      task_role_arn            = optional(string)
      execution_role_arn       = optional(string)
      network_mode             = optional(string, "bridge")
      requires_compatibilities = optional(list(string), ["EC2"])
      cpu                      = optional(string)
      memory                   = optional(string)
      container_definitions    = string

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
    }))

    service = optional(object({
      name                               = string
      task_definition                    = optional(string)
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
    }))
  })
}

variable "load_balancer" {
  description = "Load Balancer configuration (ALB/NLB)"
  type = object({
    name                             = string
    internal                         = optional(bool, false)
    load_balancer_type               = optional(string, "application")
    security_groups                  = optional(list(string))
    subnets                          = list(string)
    enable_deletion_protection       = optional(bool, false)
    enable_cross_zone_load_balancing = optional(bool, false)
    enable_http2                     = optional(bool, true)
    enable_waf_fail_open             = optional(bool, false)
    idle_timeout                     = optional(number, 60)
    ip_address_type                  = optional(string, "ipv4")

    access_logs = optional(object({
      bucket  = string
      enabled = optional(bool, false)
      prefix  = optional(string)
    }))

    subnet_mapping = optional(list(object({
      subnet_id            = string
      allocation_id        = optional(string)
      ipv6_address         = optional(string)
      private_ipv4_address = optional(string)
    })))
  })
  default = null
}

variable "target_group" {
  description = "Target Group configuration"
  type = object({
    name                 = string
    port                 = number
    protocol             = string
    vpc_id               = string
    target_type          = optional(string, "ip")
    deregistration_delay = optional(number, 300)
    slow_start           = optional(number, 0)

    health_check = optional(object({
      enabled             = optional(bool, true)
      healthy_threshold   = optional(number, 3)
      interval            = optional(number, 30)
      matcher             = optional(string, "200")
      path                = optional(string, "/")
      port                = optional(string, "traffic-port")
      protocol            = optional(string, "HTTP")
      timeout             = optional(number, 5)
      unhealthy_threshold = optional(number, 2)
    }))

    stickiness = optional(object({
      type            = string
      cookie_duration = optional(number, 86400)
      cookie_name     = optional(string)
      enabled         = optional(bool, true)
    }))
  })
  default = null
}

variable "lb_listener" {
  description = "Load Balancer Listener configuration"
  type = object({
    port            = number
    protocol        = string
    ssl_policy      = optional(string)
    certificate_arn = optional(string)

    default_action = object({
      type             = string
      target_group_arn = optional(string)

      forward = optional(object({
        target_groups = list(object({
          arn    = string
          weight = optional(number, 1)
        }))
        stickiness = optional(object({
          duration = number
          enabled  = optional(bool, false)
        }))
      }))

      redirect = optional(object({
        port        = string
        protocol    = string
        status_code = string
        host        = optional(string)
        path        = optional(string)
        query       = optional(string)
      }))

      fixed_response = optional(object({
        content_type = string
        message_body = optional(string)
        status_code  = string
      }))
    })
  })
  default = null
}

variable "ec2_autoscaling" {
  description = "EC2 Auto Scaling configuration for ECS"
  type = object({
    launch_template = object({
      name                   = string
      image_id               = string
      instance_type          = string
      key_name               = optional(string)
      iam_instance_profile   = string
      user_data              = optional(string)
      vpc_security_group_ids = optional(list(string))

      block_device_mappings = optional(list(object({
        device_name = string
        ebs = object({
          volume_size           = number
          volume_type           = optional(string, "gp3")
          delete_on_termination = optional(bool, true)
          encrypted             = optional(bool, true)
          kms_key_id            = optional(string)
          iops                  = optional(number)
          throughput            = optional(number)
        })
      })))

      monitoring = optional(object({
        enabled = optional(bool, true)
      }))

      network_interfaces = optional(list(object({
        associate_public_ip_address = optional(bool, false)
        delete_on_termination       = optional(bool, true)
        security_groups             = list(string)
        subnet_id                   = optional(string)
      })))
    })

    autoscaling_group = object({
      name                      = string
      max_size                  = number
      min_size                  = number
      desired_capacity          = number
      health_check_grace_period = optional(number, 300)
      health_check_type         = optional(string, "EC2")
      vpc_zone_identifier       = list(string)
      target_group_arns         = optional(list(string))
      termination_policies      = optional(list(string), ["Default"])
      protect_from_scale_in     = optional(bool, false)
      launch_template_version   = optional(string, "$Latest")
    })

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
  })
  default = null
}
