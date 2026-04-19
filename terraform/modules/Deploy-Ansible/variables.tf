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

variable "deploy_ansible" {
  description = "Ansible deployment configuration"
  type = object({
    attach_to_elb = optional(bool, false)
    launch_template = optional(object({
      name             = string
      instance_profile = optional(string)
      custom_ami       = optional(string)
      ami_config = object({
        os_release_date  = optional(string)
        os_base_packages = optional(string)
      })
      instance_type               = optional(string)
      key_name                    = optional(string)
      associate_public_ip_address = optional(bool)
      vpc_security_group_ids      = optional(list(string))
      tags                        = optional(map(string))
      user_data                   = optional(string)
      volume_size                 = optional(number)
      root_device_name            = optional(string)
    }))
    alb = optional(object({
      name            = string
      internal        = optional(bool, false)
      type            = optional(string, "application")
      security_groups = optional(list(string))
      vpc_name        = string
      vpc_name_abr    = optional(string)
      subnets         = optional(list(string))
      subnet_mappings = optional(list(object({
        subnet_id            = string
        private_ipv4_address = optional(string)
      })))
      enable_deletion_protection = optional(bool, false)
      enable_access_logs         = optional(bool, false)
      access_logs_bucket         = optional(string)
      access_logs_prefix         = optional(string)
      create_default_listener    = optional(bool, false)
      default_listener = optional(object({
        port            = optional(number, 443)
        protocol        = optional(string, "HTTPS")
        action_type     = optional(string, "fixed-response")
        ssl_policy      = optional(string, "ELBSecurityPolicy-2016-08")
        certificate_arn = optional(string)
        fixed_response = object({
          content_type = optional(string, "text/plain")
          message_body = optional(string, "Oops! The page you are looking for does not exist.")
          status_code  = optional(string, "200")
        })
      }))
    }))
    target_group = optional(object({
      name               = optional(string)
      port               = optional(number)
      protocol           = optional(string)
      preserve_client_ip = optional(bool)
      target_type        = optional(string)
      tags               = optional(map(string))
      vpc_id             = string
      vpc_name_abr       = optional(string)
      attachments = optional(list(object({
        target_id = optional(string)
        port      = optional(number)
      })))
      stickiness = optional(object({
        enabled         = optional(bool)
        type            = optional(string)
        cookie_duration = optional(number)
        cookie_name     = optional(string)
      }))
      health_check = optional(object({
        protocol = optional(string)
        port     = optional(number)
        path     = optional(string)
        matcher  = optional(string)
      }))
    }))
    alb_listener = optional(object({
      alb_arn          = optional(string)
      action           = optional(string, "forward")
      port             = optional(number)
      protocol         = optional(string)
      ssl_policy       = optional(string)
      certificate_arn  = optional(string)
      alt_alb_hostname = optional(string)
      vpc_id           = string
      fixed_response = optional(object({
        content_type = optional(string, "text/plain")
        message_body = optional(string, "Oops! The page you are looking for does not exist.")
        status_code  = optional(string, "200")
      }))
      sni_certificates = optional(list(object({
        domain_name     = optional(string)
        certificate_arn = optional(string)
      })))
      target_group_arn = optional(string)
      target_group = optional(object({
        name         = optional(string)
        port         = optional(number)
        protocol     = optional(string)
        vpc_name_abr = optional(string)
        attachments = optional(list(object({
          target_id = optional(string)
          port      = optional(number)
        })))
        stickiness = optional(object({
          enabled         = optional(bool)
          type            = optional(string)
          cookie_duration = optional(number)
          cookie_name     = optional(string)
        }))
        health_check = object({
          protocol = optional(string)
          port     = optional(number)
          path     = optional(string)
          matcher  = optional(string)
        })
      }))
    }))
    alb_listener_rule = optional(list(object({
      key                  = string
      listener_arn         = optional(string)
      use_default_listener = optional(bool, false)
      use_alb_listener     = optional(bool, false)
      priority             = optional(number)
      type                 = string
      target_groups = list(object({
        arn    = string
        weight = optional(number)
      }))
      conditions = list(object({
        host_headers         = optional(list(string))
        http_request_methods = optional(list(string))
        path_patterns        = optional(list(string))
        source_ips           = optional(list(string))
        http_headers = optional(list(object({
          name   = string
          values = list(string)
        })))
        query_strings = optional(list(object({
          key   = optional(string)
          value = string
        })))
      }))
    })))
    asg = optional(object({
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
    }))
  })
}