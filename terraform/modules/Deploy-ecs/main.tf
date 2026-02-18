#--------------------------------------------------------------------
# Data Sources
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_iam_roles" "admin_role" {
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}
data "aws_iam_roles" "network_role" {
  name_regex  = "AWSReservedSSO_NetworkAdministrator_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}
locals {
  admin_role_arn   = length(data.aws_iam_roles.admin_role.arns) > 0 ? sort(data.aws_iam_roles.admin_role.arns)[0] : ""
  network_role_arn = length(data.aws_iam_roles.network_role.arns) > 0 ? sort(data.aws_iam_roles.network_role.arns)[0] : ""
}

#--------------------------------------------------------------------
# ECS Cluster
#--------------------------------------------------------------------
resource "aws_ecs_cluster" "ecs" {
  name = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-${var.ecs.cluster_name}"

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

  tags = merge(var.ecs.common.tags, {
    "Name" = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-${var.ecs.cluster_name}"
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
  family                   = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-${var.ecs.task_definition.family}"
  task_role_arn            = var.ecs.task_definition.task_role_arn
  execution_role_arn       = var.ecs.task_definition.execution_role_arn
  network_mode             = var.ecs.task_definition.network_mode
  requires_compatibilities = var.ecs.task_definition.requires_compatibilities
  cpu                      = var.ecs.task_definition.cpu
  memory                   = var.ecs.task_definition.memory
  container_definitions    = var.ecs.task_definition.container_definitions_file != null ? file(var.ecs.task_definition.container_definitions_file) : var.ecs.task_definition.container_definitions

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

  tags = merge(var.ecs.common.tags, {
    "Name" = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-${var.ecs.task_definition.family}"
  })
}

#--------------------------------------------------------------------
# ECS Service
#--------------------------------------------------------------------
resource "aws_ecs_service" "ecs" {
  count                              = var.ecs.service != null ? 1 : 0
  name                               = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-${var.ecs.service.name}"
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

  tags = merge(var.ecs.common.tags, {
    "Name" = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-${var.ecs.service.name}"
  })

  depends_on = [aws_ecs_task_definition.ecs]
}

#--------------------------------------------------------------------
# EC2 Launch Template
#--------------------------------------------------------------------
resource "aws_launch_template" "ecs_ec2" {
  count         = var.ecs.ec2_autoscaling != null ? 1 : 0
  name          = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-${var.ecs.ec2_autoscaling.launch_template.name}"
  image_id      = var.ecs.ec2_autoscaling.launch_template.image_id
  instance_type = var.ecs.ec2_autoscaling.launch_template.instance_type
  key_name      = var.ecs.ec2_autoscaling.launch_template.key_name
  user_data     = var.ecs.ec2_autoscaling.launch_template.user_data != null ? base64encode(var.ecs.ec2_autoscaling.launch_template.user_data) : null

  iam_instance_profile {
    name = var.ecs.ec2_autoscaling.launch_template.iam_instance_profile
  }

  dynamic "block_device_mappings" {
    for_each = var.ecs.ec2_autoscaling.launch_template.block_device_mappings != null ? var.ecs.ec2_autoscaling.launch_template.block_device_mappings : []
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
    for_each = var.ecs.ec2_autoscaling.launch_template.monitoring != null ? [var.ecs.ec2_autoscaling.launch_template.monitoring] : []
    content {
      enabled = monitoring.value.enabled
    }
  }

  dynamic "network_interfaces" {
    for_each = var.ecs.ec2_autoscaling.launch_template.network_interfaces != null ? var.ecs.ec2_autoscaling.launch_template.network_interfaces : []
    content {
      associate_public_ip_address = network_interfaces.value.associate_public_ip_address
      delete_on_termination       = network_interfaces.value.delete_on_termination
      security_groups             = network_interfaces.value.security_groups
      subnet_id                   = network_interfaces.value.subnet_id
    }
  }

  vpc_security_group_ids = var.ecs.ec2_autoscaling.launch_template.vpc_security_group_ids

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.ecs.common.tags, {
      "Name" = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-ecs-instance"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.ecs.common.tags, {
      "Name" = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-ecs-volume"
    })
  }

  tags = merge(var.ecs.common.tags, {
    "Name" = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-${var.ecs.ec2_autoscaling.launch_template.name}"
  })
}

#--------------------------------------------------------------------
# EC2 Auto Scaling Group
#--------------------------------------------------------------------
resource "aws_autoscaling_group" "ecs_ec2" {
  count                     = var.ecs.ec2_autoscaling != null ? 1 : 0
  name                      = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-${var.ecs.ec2_autoscaling.autoscaling_group.name}"
  max_size                  = var.ecs.ec2_autoscaling.autoscaling_group.max_size
  min_size                  = var.ecs.ec2_autoscaling.autoscaling_group.min_size
  desired_capacity          = var.ecs.ec2_autoscaling.autoscaling_group.desired_capacity
  health_check_grace_period = var.ecs.ec2_autoscaling.autoscaling_group.health_check_grace_period
  health_check_type         = var.ecs.ec2_autoscaling.autoscaling_group.health_check_type
  vpc_zone_identifier       = var.ecs.ec2_autoscaling.autoscaling_group.vpc_zone_identifier
  target_group_arns         = var.ecs.ec2_autoscaling.autoscaling_group.target_group_arns
  termination_policies      = var.ecs.ec2_autoscaling.autoscaling_group.termination_policies
  protect_from_scale_in     = var.ecs.ec2_autoscaling.autoscaling_group.protect_from_scale_in

  launch_template {
    id      = aws_launch_template.ecs_ec2[0].id
    version = var.ecs.ec2_autoscaling.autoscaling_group.launch_template_version
  }

  dynamic "tag" {
    for_each = merge(var.ecs.common.tags, {
      "Name" = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-ecs-asg"
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
# ECS Capacity Provider (EC2)
#--------------------------------------------------------------------
resource "aws_ecs_capacity_provider" "ecs_ec2" {
  count = var.ecs.ec2_autoscaling != null ? 1 : 0
  name  = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-${var.ecs.ec2_autoscaling.capacity_provider.name}"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_ec2[0].arn
    managed_termination_protection = var.ecs.ec2_autoscaling.capacity_provider.managed_termination_protection

    managed_scaling {
      maximum_scaling_step_size = var.ecs.ec2_autoscaling.capacity_provider.managed_scaling.maximum_scaling_step_size
      minimum_scaling_step_size = var.ecs.ec2_autoscaling.capacity_provider.managed_scaling.minimum_scaling_step_size
      status                    = var.ecs.ec2_autoscaling.capacity_provider.managed_scaling.status
      target_capacity           = var.ecs.ec2_autoscaling.capacity_provider.managed_scaling.target_capacity
      instance_warmup_period    = var.ecs.ec2_autoscaling.capacity_provider.managed_scaling.instance_warmup_period
    }
  }

  tags = merge(var.ecs.common.tags, {
    "Name" = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-${var.ecs.ec2_autoscaling.capacity_provider.name}"
  })
}

#--------------------------------------------------------------------
# Auto Scaling Policies
#--------------------------------------------------------------------
resource "aws_autoscaling_policy" "ecs_scale_up" {
  count                  = var.ecs.ec2_autoscaling != null && var.ecs.ec2_autoscaling.scaling_policies != null ? 1 : 0
  name                   = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-ecs-scale-up"
  scaling_adjustment     = var.ecs.ec2_autoscaling.scaling_policies.scale_up.scaling_adjustment
  adjustment_type        = var.ecs.ec2_autoscaling.scaling_policies.scale_up.adjustment_type
  cooldown               = var.ecs.ec2_autoscaling.scaling_policies.scale_up.cooldown
  autoscaling_group_name = aws_autoscaling_group.ecs_ec2[0].name
}

resource "aws_autoscaling_policy" "ecs_scale_down" {
  count                  = var.ecs.ec2_autoscaling != null && var.ecs.ec2_autoscaling.scaling_policies != null ? 1 : 0
  name                   = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-ecs-scale-down"
  scaling_adjustment     = var.ecs.ec2_autoscaling.scaling_policies.scale_down.scaling_adjustment
  adjustment_type        = var.ecs.ec2_autoscaling.scaling_policies.scale_down.adjustment_type
  cooldown               = var.ecs.ec2_autoscaling.scaling_policies.scale_down.cooldown
  autoscaling_group_name = aws_autoscaling_group.ecs_ec2[0].name
}
