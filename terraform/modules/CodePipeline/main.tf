#--------------------------------------------------------------------
# ECS Cluster
#--------------------------------------------------------------------
resource "aws_ecs_cluster" "ecs" {
  name = "${var.common.account_name}-${var.common.region_prefix}-${var.ecs.cluster_name}"

  dynamic "setting" {
    for_each = var.ecs.container_insights_enabled ? [1] : []
    content {
      name  = "containerInsights"
      value = "enabled"
    }
  }

  dynamic "configuration" {
    for_each = var.ecs.execute_command_configuration != null ? [1] : []
    content {
      execute_command_configuration {
        kms_key_id = var.ecs.execute_command_configuration.kms_key_id
        logging    = var.ecs.execute_command_configuration.logging

        dynamic "log_configuration" {
          for_each = var.ecs.execute_command_configuration.log_configuration != null ? [1] : []
          content {
            cloud_watch_encryption_enabled = var.ecs.execute_command_configuration.log_configuration.cloud_watch_encryption_enabled
            cloud_watch_log_group_name     = var.ecs.execute_command_configuration.log_configuration.cloud_watch_log_group_name
            s3_bucket_name                 = var.ecs.execute_command_configuration.log_configuration.s3_bucket_name
            s3_bucket_encryption_enabled   = var.ecs.execute_command_configuration.log_configuration.s3_bucket_encryption_enabled
            s3_key_prefix                  = var.ecs.execute_command_configuration.log_configuration.s3_key_prefix
          }
        }
      }
    }
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.ecs.cluster_name}"
  })
}

#--------------------------------------------------------------------
# ECS Cluster Capacity Providers
#--------------------------------------------------------------------
resource "aws_ecs_cluster_capacity_providers" "ecs" {
  count        = var.ecs.capacity_providers != null ? 1 : 0
  cluster_name = aws_ecs_cluster.ecs.name

  capacity_providers = var.ecs.capacity_providers.capacity_provider_names

  dynamic "default_capacity_provider_strategy" {
    for_each = var.ecs.capacity_providers.default_capacity_provider_strategy != null ? var.ecs.capacity_providers.default_capacity_provider_strategy : []
    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      weight            = default_capacity_provider_strategy.value.weight
      base              = default_capacity_provider_strategy.value.base
    }
  }
}

#--------------------------------------------------------------------
# ECS Task Definition
#--------------------------------------------------------------------
resource "aws_ecs_task_definition" "ecs" {
  count                    = var.ecs.task_definition != null ? 1 : 0
  family                   = "${var.common.account_name}-${var.common.region_prefix}-${var.ecs.task_definition.family}"
  task_role_arn            = var.ecs.task_definition.task_role_arn
  execution_role_arn       = var.ecs.task_definition.execution_role_arn
  network_mode             = var.ecs.task_definition.network_mode
  requires_compatibilities = var.ecs.task_definition.requires_compatibilities
  cpu                      = var.ecs.task_definition.cpu
  memory                   = var.ecs.task_definition.memory
  container_definitions    = var.ecs.task_definition.container_definitions

  dynamic "volume" {
    for_each = var.ecs.task_definition.volumes != null ? var.ecs.task_definition.volumes : []
    content {
      name      = volume.value.name
      host_path = volume.value.host_path

      dynamic "docker_volume_configuration" {
        for_each = volume.value.docker_volume_configuration != null ? [volume.value.docker_volume_configuration] : []
        content {
          scope         = docker_volume_configuration.value.scope
          autoprovision = docker_volume_configuration.value.autoprovision
          driver        = docker_volume_configuration.value.driver
          driver_opts   = docker_volume_configuration.value.driver_opts
          labels        = docker_volume_configuration.value.labels
        }
      }

      dynamic "efs_volume_configuration" {
        for_each = volume.value.efs_volume_configuration != null ? [volume.value.efs_volume_configuration] : []
        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = efs_volume_configuration.value.root_directory
          transit_encryption      = efs_volume_configuration.value.transit_encryption
          transit_encryption_port = efs_volume_configuration.value.transit_encryption_port

          dynamic "authorization_config" {
            for_each = efs_volume_configuration.value.authorization_config != null ? [efs_volume_configuration.value.authorization_config] : []
            content {
              access_point_id = authorization_config.value.access_point_id
              iam             = authorization_config.value.iam
            }
          }
        }
      }
    }
  }

  dynamic "placement_constraints" {
    for_each = var.ecs.task_definition.placement_constraints != null ? var.ecs.task_definition.placement_constraints : []
    content {
      type       = placement_constraints.value.type
      expression = placement_constraints.value.expression
    }
  }

  dynamic "proxy_configuration" {
    for_each = var.ecs.task_definition.proxy_configuration != null ? [var.ecs.task_definition.proxy_configuration] : []
    content {
      container_name = proxy_configuration.value.container_name
      properties     = proxy_configuration.value.properties
      type           = proxy_configuration.value.type
    }
  }

  dynamic "runtime_platform" {
    for_each = var.ecs.task_definition.runtime_platform != null ? [var.ecs.task_definition.runtime_platform] : []
    content {
      operating_system_family = runtime_platform.value.operating_system_family
      cpu_architecture        = runtime_platform.value.cpu_architecture
    }
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.ecs.task_definition.family}"
  })
}

#--------------------------------------------------------------------
# ECS Service
#--------------------------------------------------------------------
resource "aws_ecs_service" "ecs" {
  count                              = var.ecs.service != null ? 1 : 0
  name                               = "${var.common.account_name}-${var.common.region_prefix}-${var.ecs.service.name}"
  cluster                            = aws_ecs_cluster.ecs.id
  task_definition                    = var.ecs.service.task_definition != null ? var.ecs.service.task_definition : aws_ecs_task_definition.ecs[0].arn
  desired_count                      = var.ecs.service.desired_count
  launch_type                        = var.ecs.service.launch_type
  platform_version                   = var.ecs.service.platform_version
  scheduling_strategy                = var.ecs.service.scheduling_strategy
  deployment_maximum_percent         = var.ecs.service.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.ecs.service.deployment_minimum_healthy_percent
  enable_ecs_managed_tags            = var.ecs.service.enable_ecs_managed_tags
  enable_execute_command             = var.ecs.service.enable_execute_command
  health_check_grace_period_seconds  = var.ecs.service.health_check_grace_period_seconds
  propagate_tags                     = var.ecs.service.propagate_tags

  dynamic "capacity_provider_strategy" {
    for_each = var.ecs.service.capacity_provider_strategy != null ? var.ecs.service.capacity_provider_strategy : []
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = capacity_provider_strategy.value.base
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.ecs.service.deployment_circuit_breaker != null ? [var.ecs.service.deployment_circuit_breaker] : []
    content {
      enable   = deployment_circuit_breaker.value.enable
      rollback = deployment_circuit_breaker.value.rollback
    }
  }

  dynamic "deployment_controller" {
    for_each = var.ecs.service.deployment_controller != null ? [var.ecs.service.deployment_controller] : []
    content {
      type = deployment_controller.value.type
    }
  }

  dynamic "load_balancer" {
    for_each = var.ecs.service.load_balancers != null ? var.ecs.service.load_balancers : []
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  dynamic "network_configuration" {
    for_each = var.ecs.service.network_configuration != null ? [var.ecs.service.network_configuration] : []
    content {
      subnets          = network_configuration.value.subnets
      security_groups  = network_configuration.value.security_groups
      assign_public_ip = network_configuration.value.assign_public_ip
    }
  }

  dynamic "placement_constraints" {
    for_each = var.ecs.service.placement_constraints != null ? var.ecs.service.placement_constraints : []
    content {
      type       = placement_constraints.value.type
      expression = placement_constraints.value.expression
    }
  }

  dynamic "ordered_placement_strategy" {
    for_each = var.ecs.service.ordered_placement_strategy != null ? var.ecs.service.ordered_placement_strategy : []
    content {
      type  = ordered_placement_strategy.value.type
      field = ordered_placement_strategy.value.field
    }
  }

  dynamic "service_registries" {
    for_each = var.ecs.service.service_registries != null ? [var.ecs.service.service_registries] : []
    content {
      registry_arn   = service_registries.value.registry_arn
      port           = service_registries.value.port
      container_name = service_registries.value.container_name
      container_port = service_registries.value.container_port
    }
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.ecs.service.name}"
  })

  depends_on = [aws_ecs_task_definition.ecs]
}

#--------------------------------------------------------------------
# Load Balancer (ALB/NLB)
#--------------------------------------------------------------------
resource "aws_lb" "ecs" {
  count              = var.load_balancer != null ? 1 : 0
  name               = "${var.common.account_name}-${var.common.region_prefix}-${var.load_balancer.name}"
  internal           = var.load_balancer.internal
  load_balancer_type = var.load_balancer.load_balancer_type
  security_groups    = var.load_balancer.security_groups
  subnets            = var.load_balancer.subnets

  enable_deletion_protection       = var.load_balancer.enable_deletion_protection
  enable_cross_zone_load_balancing = var.load_balancer.enable_cross_zone_load_balancing
  enable_http2                     = var.load_balancer.enable_http2
  enable_waf_fail_open             = var.load_balancer.enable_waf_fail_open
  idle_timeout                     = var.load_balancer.idle_timeout
  ip_address_type                  = var.load_balancer.ip_address_type

  dynamic "access_logs" {
    for_each = var.load_balancer.access_logs != null ? [var.load_balancer.access_logs] : []
    content {
      bucket  = access_logs.value.bucket
      enabled = access_logs.value.enabled
      prefix  = access_logs.value.prefix
    }
  }

  dynamic "subnet_mapping" {
    for_each = var.load_balancer.subnet_mapping != null ? var.load_balancer.subnet_mapping : []
    content {
      subnet_id            = subnet_mapping.value.subnet_id
      allocation_id        = subnet_mapping.value.allocation_id
      ipv6_address         = subnet_mapping.value.ipv6_address
      private_ipv4_address = subnet_mapping.value.private_ipv4_address
    }
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.load_balancer.name}"
  })
}

#--------------------------------------------------------------------
# Target Group
#--------------------------------------------------------------------
resource "aws_lb_target_group" "ecs" {
  count                = var.target_group != null ? 1 : 0
  name                 = "${var.common.account_name}-${var.common.region_prefix}-${var.target_group.name}"
  port                 = var.target_group.port
  protocol             = var.target_group.protocol
  vpc_id               = var.target_group.vpc_id
  target_type          = var.target_group.target_type
  deregistration_delay = var.target_group.deregistration_delay
  slow_start           = var.target_group.slow_start

  dynamic "health_check" {
    for_each = var.target_group.health_check != null ? [var.target_group.health_check] : []
    content {
      enabled             = health_check.value.enabled
      healthy_threshold   = health_check.value.healthy_threshold
      interval            = health_check.value.interval
      matcher             = health_check.value.matcher
      path                = health_check.value.path
      port                = health_check.value.port
      protocol            = health_check.value.protocol
      timeout             = health_check.value.timeout
      unhealthy_threshold = health_check.value.unhealthy_threshold
    }
  }

  dynamic "stickiness" {
    for_each = var.target_group.stickiness != null ? [var.target_group.stickiness] : []
    content {
      type            = stickiness.value.type
      cookie_duration = stickiness.value.cookie_duration
      cookie_name     = stickiness.value.cookie_name
      enabled         = stickiness.value.enabled
    }
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.target_group.name}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

#--------------------------------------------------------------------
# Load Balancer Listener
#--------------------------------------------------------------------
resource "aws_lb_listener" "ecs" {
  count             = var.lb_listener != null ? 1 : 0
  load_balancer_arn = aws_lb.ecs[0].arn
  port              = var.lb_listener.port
  protocol          = var.lb_listener.protocol
  ssl_policy        = var.lb_listener.ssl_policy
  certificate_arn   = var.lb_listener.certificate_arn

  default_action {
    type             = var.lb_listener.default_action.type
    target_group_arn = var.lb_listener.default_action.target_group_arn != null ? var.lb_listener.default_action.target_group_arn : aws_lb_target_group.ecs[0].arn

    dynamic "forward" {
      for_each = var.lb_listener.default_action.forward != null ? [var.lb_listener.default_action.forward] : []
      content {
        dynamic "target_group" {
          for_each = forward.value.target_groups
          content {
            arn    = target_group.value.arn
            weight = target_group.value.weight
          }
        }
        dynamic "stickiness" {
          for_each = forward.value.stickiness != null ? [forward.value.stickiness] : []
          content {
            duration = stickiness.value.duration
            enabled  = stickiness.value.enabled
          }
        }
      }
    }

    dynamic "redirect" {
      for_each = var.lb_listener.default_action.redirect != null ? [var.lb_listener.default_action.redirect] : []
      content {
        port        = redirect.value.port
        protocol    = redirect.value.protocol
        status_code = redirect.value.status_code
        host        = redirect.value.host
        path        = redirect.value.path
        query       = redirect.value.query
      }
    }

    dynamic "fixed_response" {
      for_each = var.lb_listener.default_action.fixed_response != null ? [var.lb_listener.default_action.fixed_response] : []
      content {
        content_type = fixed_response.value.content_type
        message_body = fixed_response.value.message_body
        status_code  = fixed_response.value.status_code
      }
    }
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-lb-listener"
  })
}

#--------------------------------------------------------------------
# Launch Template for EC2
#--------------------------------------------------------------------
resource "aws_launch_template" "ecs_ec2" {
  count         = var.ec2_autoscaling != null ? 1 : 0
  name          = "${var.common.account_name}-${var.common.region_prefix}-${var.ec2_autoscaling.launch_template.name}"
  image_id      = var.ec2_autoscaling.launch_template.image_id
  instance_type = var.ec2_autoscaling.launch_template.instance_type
  key_name      = var.ec2_autoscaling.launch_template.key_name
  user_data     = var.ec2_autoscaling.launch_template.user_data != null ? base64encode(var.ec2_autoscaling.launch_template.user_data) : null

  iam_instance_profile {
    name = var.ec2_autoscaling.launch_template.iam_instance_profile
  }

  dynamic "block_device_mappings" {
    for_each = var.ec2_autoscaling.launch_template.block_device_mappings != null ? var.ec2_autoscaling.launch_template.block_device_mappings : []
    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        volume_size           = block_device_mappings.value.ebs.volume_size
        volume_type           = block_device_mappings.value.ebs.volume_type
        delete_on_termination = block_device_mappings.value.ebs.delete_on_termination
        encrypted             = block_device_mappings.value.ebs.encrypted
        kms_key_id            = block_device_mappings.value.ebs.kms_key_id
        iops                  = block_device_mappings.value.ebs.iops
        throughput            = block_device_mappings.value.ebs.throughput
      }
    }
  }

  dynamic "monitoring" {
    for_each = var.ec2_autoscaling.launch_template.monitoring != null ? [var.ec2_autoscaling.launch_template.monitoring] : []
    content {
      enabled = monitoring.value.enabled
    }
  }

  dynamic "network_interfaces" {
    for_each = var.ec2_autoscaling.launch_template.network_interfaces != null ? var.ec2_autoscaling.launch_template.network_interfaces : []
    content {
      associate_public_ip_address = network_interfaces.value.associate_public_ip_address
      delete_on_termination       = network_interfaces.value.delete_on_termination
      security_groups             = network_interfaces.value.security_groups
      subnet_id                   = network_interfaces.value.subnet_id
    }
  }

  vpc_security_group_ids = var.ec2_autoscaling.launch_template.vpc_security_group_ids

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common.tags, {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-ecs-instance"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.common.tags, {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-ecs-volume"
    })
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.ec2_autoscaling.launch_template.name}"
  })
}

#--------------------------------------------------------------------
# Auto Scaling Group for EC2
#--------------------------------------------------------------------
resource "aws_autoscaling_group" "ecs_ec2" {
  count                     = var.ec2_autoscaling != null ? 1 : 0
  name                      = "${var.common.account_name}-${var.common.region_prefix}-${var.ec2_autoscaling.autoscaling_group.name}"
  max_size                  = var.ec2_autoscaling.autoscaling_group.max_size
  min_size                  = var.ec2_autoscaling.autoscaling_group.min_size
  desired_capacity          = var.ec2_autoscaling.autoscaling_group.desired_capacity
  health_check_grace_period = var.ec2_autoscaling.autoscaling_group.health_check_grace_period
  health_check_type         = var.ec2_autoscaling.autoscaling_group.health_check_type
  vpc_zone_identifier       = var.ec2_autoscaling.autoscaling_group.vpc_zone_identifier
  target_group_arns         = var.ec2_autoscaling.autoscaling_group.target_group_arns
  termination_policies      = var.ec2_autoscaling.autoscaling_group.termination_policies
  protect_from_scale_in     = var.ec2_autoscaling.autoscaling_group.protect_from_scale_in

  launch_template {
    id      = aws_launch_template.ecs_ec2[0].id
    version = var.ec2_autoscaling.autoscaling_group.launch_template_version
  }

  dynamic "tag" {
    for_each = merge(var.common.tags, {
      "Name" = "${var.common.account_name}-${var.common.region_prefix}-ecs-asg"
    })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

#--------------------------------------------------------------------
# ECS Capacity Provider for EC2
#--------------------------------------------------------------------
resource "aws_ecs_capacity_provider" "ecs_ec2" {
  count = var.ec2_autoscaling != null ? 1 : 0
  name  = "${var.common.account_name}-${var.common.region_prefix}-${var.ec2_autoscaling.capacity_provider.name}"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_ec2[0].arn
    managed_termination_protection = var.ec2_autoscaling.capacity_provider.managed_termination_protection

    managed_scaling {
      maximum_scaling_step_size = var.ec2_autoscaling.capacity_provider.managed_scaling.maximum_scaling_step_size
      minimum_scaling_step_size = var.ec2_autoscaling.capacity_provider.managed_scaling.minimum_scaling_step_size
      status                    = var.ec2_autoscaling.capacity_provider.managed_scaling.status
      target_capacity           = var.ec2_autoscaling.capacity_provider.managed_scaling.target_capacity
      instance_warmup_period    = var.ec2_autoscaling.capacity_provider.managed_scaling.instance_warmup_period
    }
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${var.ec2_autoscaling.capacity_provider.name}"
  })
}

#--------------------------------------------------------------------
# Auto Scaling Policies (Optional)
#--------------------------------------------------------------------
resource "aws_autoscaling_policy" "ecs_scale_up" {
  count                  = var.ec2_autoscaling != null && var.ec2_autoscaling.scaling_policies != null ? 1 : 0
  name                   = "${var.common.account_name}-${var.common.region_prefix}-ecs-scale-up"
  scaling_adjustment     = var.ec2_autoscaling.scaling_policies.scale_up.scaling_adjustment
  adjustment_type        = var.ec2_autoscaling.scaling_policies.scale_up.adjustment_type
  cooldown               = var.ec2_autoscaling.scaling_policies.scale_up.cooldown
  autoscaling_group_name = aws_autoscaling_group.ecs_ec2[0].name
}

resource "aws_autoscaling_policy" "ecs_scale_down" {
  count                  = var.ec2_autoscaling != null && var.ec2_autoscaling.scaling_policies != null ? 1 : 0
  name                   = "${var.common.account_name}-${var.common.region_prefix}-ecs-scale-down"
  scaling_adjustment     = var.ec2_autoscaling.scaling_policies.scale_down.scaling_adjustment
  adjustment_type        = var.ec2_autoscaling.scaling_policies.scale_down.adjustment_type
  cooldown               = var.ec2_autoscaling.scaling_policies.scale_down.cooldown
  autoscaling_group_name = aws_autoscaling_group.ecs_ec2[0].name
}
