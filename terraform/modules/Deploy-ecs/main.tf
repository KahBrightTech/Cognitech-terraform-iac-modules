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

  task_definitions_map = { for td in var.ecs.task_definitions : td.family => td }
  services_map         = { for svc in var.ecs.services : svc.name => svc }
}

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
  for_each                 = local.task_definitions_map
  family                   = "${var.common.account_name}-${var.common.region_prefix}-${each.value.family}"
  task_role_arn            = each.value.task_role_arn
  execution_role_arn       = each.value.execution_role_arn
  network_mode             = each.value.network_mode
  requires_compatibilities = each.value.requires_compatibilities
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  container_definitions    = each.value.container_definitions_file != null ? file(each.value.container_definitions_file) : each.value.container_definitions

  dynamic "volume" {
    for_each = each.value.volumes != null ? each.value.volumes : []
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
    for_each = each.value.placement_constraints != null ? each.value.placement_constraints : []
    content {
      type       = placement_constraints.value.type
      expression = placement_constraints.value.expression
    }
  }

  dynamic "proxy_configuration" {
    for_each = each.value.proxy_configuration != null ? [each.value.proxy_configuration] : []
    content {
      container_name = proxy_configuration.value.container_name
      properties     = proxy_configuration.value.properties
      type           = proxy_configuration.value.type
    }
  }

  dynamic "runtime_platform" {
    for_each = each.value.runtime_platform != null ? [each.value.runtime_platform] : []
    content {
      operating_system_family = runtime_platform.value.operating_system_family
      cpu_architecture        = runtime_platform.value.cpu_architecture
    }
  }

  tags = merge(var.common.tags, {
    "Name" = "${var.common.account_name}-${var.common.region_prefix}-${each.value.family}"
  })
}

#--------------------------------------------------------------------
# ECS Services
#--------------------------------------------------------------------
resource "aws_ecs_service" "ecs" {
  for_each                           = local.services_map
  name                               = "${var.common.account_name}-${var.common.region_prefix}-${each.value.name}"
  cluster                            = aws_ecs_cluster.ecs.id
  task_definition                    = each.value.task_definition != null ? each.value.task_definition : aws_ecs_task_definition.ecs[each.value.task_definition_family].arn
  desired_count                      = each.value.desired_count
  launch_type                        = each.value.launch_type
  platform_version                   = each.value.platform_version
  scheduling_strategy                = each.value.scheduling_strategy
  deployment_maximum_percent         = each.value.deployment_maximum_percent
  deployment_minimum_healthy_percent = each.value.deployment_minimum_healthy_percent
  enable_ecs_managed_tags            = each.value.enable_ecs_managed_tags
  enable_execute_command             = each.value.enable_execute_command
  health_check_grace_period_seconds  = each.value.health_check_grace_period_seconds
  propagate_tags                     = each.value.propagate_tags

  dynamic "capacity_provider_strategy" {
    for_each = each.value.capacity_provider_strategy != null ? each.value.capacity_provider_strategy : []
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
      base              = capacity_provider_strategy.value.base
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = each.value.deployment_circuit_breaker != null ? [each.value.deployment_circuit_breaker] : []
    content {
      enable   = deployment_circuit_breaker.value.enable
      rollback = deployment_circuit_breaker.value.rollback
    }
  }

  dynamic "deployment_controller" {
    for_each = each.value.deployment_controller != null ? [each.value.deployment_controller] : []
    content {
      type = deployment_controller.value.type
    }
  }

  dynamic "load_balancer" {
    for_each = each.value.load_balancers != null ? each.value.load_balancers : []
    content {
      target_group_arn = load_balancer.value.target_group_arn
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  dynamic "network_configuration" {
    for_each = each.value.network_configuration != null ? [each.value.network_configuration] : []
    content {
      subnets          = network_configuration.value.subnets
      security_groups  = network_configuration.value.security_groups
      assign_public_ip = network_configuration.value.assign_public_ip
    }
  }

  dynamic "placement_constraints" {
    for_each = each.value.placement_constraints != null ? each.value.placement_constraints : []
    content {
      type       = placement_constraints.value.type
      expression = placement_constraints.value.expression
    }
  }

  dynamic "ordered_placement_strategy" {
    for_each = each.value.ordered_placement_strategy != null ? each.value.ordered_placement_strategy : []
    content {
      type  = ordered_placement_strategy.value.type
      field = ordered_placement_strategy.value.field
    }
  }

  dynamic "service_registries" {
    for_each = each.value.service_registries != null ? [each.value.service_registries] : []
    content {
      registry_arn   = service_registries.value.registry_arn
      port           = service_registries.value.port
      container_name = service_registries.value.container_name
      container_port = service_registries.value.container_port
    }
  }

  tags = merge(var.ecs.common.tags, {
    "Name" = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-${each.value.name}"
  })

  depends_on = [aws_ecs_task_definition.ecs]
}

#--------------------------------------------------------------------
# Launch Template
#--------------------------------------------------------------------
module "launch_template" {
  for_each = var.ecs.ec2_autoscaling != null ? { for item in flatten([for asg in var.ecs.ec2_autoscaling : asg.launch_templates != null ? asg.launch_templates : []]) : item.key => item
  } : {}
  source          = "../Launch_template"
  common          = var.common
  launch_template = each.value
}
#--------------------------------------------------------------------
# EC2 Auto Scaling Group
#--------------------------------------------------------------------
module "autoscaling_group" {
  for_each = var.ecs.ec2_autoscaling != null ? { for item in flatten([for asg in var.ecs.ec2_autoscaling : asg.autoscaling_group != null ? asg.autoscaling_group : []]) : item.name => item } : {}
  source   = "../AutoScaling"
  common   = var.common
  Autoscaling_group = merge(
    each.value,
    {
      launch_template = each.value.launch_template_key != null ? {
        id      = module.launch_template[each.value.launch_template_key].id
        version = try(each.value.launch_template.version, "$Latest")
      } : each.value.launch_template
    }
  )
}

#--------------------------------------------------------------------
# ECS Capacity Provider (EC2)
#--------------------------------------------------------------------
resource "aws_ecs_capacity_provider" "ecs_ec2" {
  count = var.ecs.ec2_autoscaling != null ? 1 : 0
  name  = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-${var.ecs.ec2_autoscaling.capacity_provider.name}"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = module.autoscaling_group[keys(module.autoscaling_group)[0]].arn
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
  autoscaling_group_name = module.autoscaling_group[keys(module.autoscaling_group)[0]].name
}

resource "aws_autoscaling_policy" "ecs_scale_down" {
  count                  = var.ecs.ec2_autoscaling != null && var.ecs.ec2_autoscaling.scaling_policies != null ? 1 : 0
  name                   = "${var.ecs.common.account_name}-${var.ecs.common.region_prefix}-ecs-scale-down"
  scaling_adjustment     = var.ecs.ec2_autoscaling.scaling_policies.scale_down.scaling_adjustment
  adjustment_type        = var.ecs.ec2_autoscaling.scaling_policies.scale_down.adjustment_type
  cooldown               = var.ecs.ec2_autoscaling.scaling_policies.scale_down.cooldown
  autoscaling_group_name = module.autoscaling_group[keys(module.autoscaling_group)[0]].name
}
