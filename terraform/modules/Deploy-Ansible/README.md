# Deploy-Ansible Module

This module deploys an Ansible instance using a Launch Template, Auto Scaling Group, and optionally an Application Load Balancer (ALB) with a target group, listener, and listener rules.

## Usage

### Terragrunt Configuration

Below are two examples: one **without** an ALB (just the instance + ASG) and one **with** an ALB attached.

---

### Example 1: Ansible Instance Only (No ALB)

```hcl
# terragrunt.hcl

terraform {
  source = "git::https://github.com/KahBrightTech/Cognitech-terraform-iac-modules.git//terraform/modules/Deploy-Ansible"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "security_group" {
  config_path = "../security-group"
}

inputs = {
  common = {
    global           = false
    tags             = { Environment = "dev", Project = "ansible" }
    account_name     = "my-account"
    region_prefix    = "use1"
    account_name_abr = "myacct"
  }

  deploy_ansible = {
    attach_to_elb = false  # No ALB resources created

    launch_template = {
      name             = "ansible"
      instance_profile = "ansible-instance-profile"
      instance_type    = "t3.medium"
      key_name         = "my-key-pair"
      volume_size      = 30
      root_device_name = "/dev/xvda"
      ami_config = {
        os_release_date  = "2026.01"
        os_base_packages = "amazon-linux-2023"
      }
      vpc_security_group_ids = [dependency.security_group.outputs.id]
      user_data = filebase64("${get_terragrunt_dir()}/user-data.sh")
      tags = {
        Role = "ansible"
      }
    }

    asg = {
      name                      = "ansible"
      min_size                  = 1
      max_size                  = 3
      desired_capacity          = 1
      health_check_type         = "EC2"
      health_check_grace_period = 300
      force_delete              = false
      subnet_ids                = dependency.vpc.outputs.private_subnet_ids
      tags = {
        Name = "ansible-instance"
      }
    }
  }
}
```

---

### Example 2: Ansible Instance Attached to an ALB

```hcl
# terragrunt.hcl

terraform {
  source = "git::https://github.com/KahBrightTech/Cognitech-terraform-iac-modules.git//terraform/modules/Deploy-Ansible"
}

include "root" {
  path = find_in_parent_folders()
}

dependency "vpc" {
  config_path = "../vpc"
}

dependency "security_group" {
  config_path = "../security-group"
}

dependency "acm" {
  config_path = "../acm-certificate"
}

inputs = {
  common = {
    global           = false
    tags             = { Environment = "dev", Project = "ansible" }
    account_name     = "my-account"
    region_prefix    = "use1"
    account_name_abr = "myacct"
  }

  deploy_ansible = {
    attach_to_elb = true  # Enables ALB, Target Group, Listener, and Rules

    # ---------------------------------------------------------------
    # Launch Template
    # ---------------------------------------------------------------
    launch_template = {
      name             = "ansible"
      instance_profile = "ansible-instance-profile"
      instance_type    = "t3.medium"
      key_name         = "my-key-pair"
      volume_size      = 30
      root_device_name = "/dev/xvda"
      ami_config = {
        os_release_date  = "2026.01"
        os_base_packages = "amazon-linux-2023"
      }
      vpc_security_group_ids = [dependency.security_group.outputs.id]
      user_data = filebase64("${get_terragrunt_dir()}/user-data.sh")
      tags = {
        Role = "ansible"
      }
    }

    # ---------------------------------------------------------------
    # Application Load Balancer
    # ---------------------------------------------------------------
    alb = {
      name                       = "ansible"
      internal                   = true
      type                       = "application"
      vpc_name                   = "main-vpc"
      vpc_name_abr               = "main"
      security_groups            = [dependency.security_group.outputs.id]
      subnets                    = dependency.vpc.outputs.private_subnet_ids
      enable_deletion_protection = false
      enable_access_logs         = false
      create_default_listener    = true
      default_listener = {
        port            = 443
        protocol        = "HTTPS"
        ssl_policy      = "ELBSecurityPolicy-2016-08"
        certificate_arn = dependency.acm.outputs.arn
        fixed_response = {
          content_type = "text/plain"
          message_body = "Not Found"
          status_code  = "404"
        }
      }
    }

    # ---------------------------------------------------------------
    # Target Group
    # ---------------------------------------------------------------
    target_group = {
      name         = "ansible"
      port         = 8080
      protocol     = "HTTP"
      target_type  = "instance"
      vpc_id       = dependency.vpc.outputs.vpc_id
      vpc_name_abr = "main"
      health_check = {
        protocol = "HTTP"
        port     = 8080
        path     = "/health"
        matcher  = "200"
      }
    }

    # ---------------------------------------------------------------
    # ALB Listener (forwards traffic to target group)
    # ---------------------------------------------------------------
    alb_listener = {
      # alb_arn is auto-wired from the ALB module when omitted
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-2016-08"
      certificate_arn = dependency.acm.outputs.arn
      action          = "forward"
      vpc_id          = dependency.vpc.outputs.vpc_id
    }

    # ---------------------------------------------------------------
    # ALB Listener Rules (optional)
    # ---------------------------------------------------------------
    alb_listener_rule = [
      {
        key      = "ansible-api"
        priority = 100
        type     = "forward"
        target_groups = [
          {
            arn    = "auto"  # Replace with actual TG ARN or reference
            weight = 100
          }
        ]
        conditions = [
          {
            path_patterns = ["/api/*"]
          }
        ]
      },
      {
        key      = "ansible-ui"
        priority = 200
        type     = "forward"
        target_groups = [
          {
            arn    = "auto"  # Replace with actual TG ARN or reference
            weight = 100
          }
        ]
        conditions = [
          {
            host_headers = ["ansible.example.com"]
          }
        ]
      }
    ]

    # ---------------------------------------------------------------
    # Auto Scaling Group
    # Note: launch_template and attach_target_groups are auto-wired
    # ---------------------------------------------------------------
    asg = {
      name                      = "ansible"
      min_size                  = 1
      max_size                  = 3
      desired_capacity          = 1
      health_check_type         = "ELB"  # Use ELB health checks when attached to ALB
      health_check_grace_period = 300
      force_delete              = false
      subnet_ids                = dependency.vpc.outputs.private_subnet_ids
      tags = {
        Name = "ansible-instance"
      }
    }
  }
}
```

---

## Key Behaviors

| Setting | Effect |
|---|---|
| `attach_to_elb = false` | Only Launch Template + ASG are created. No ALB, target group, listener, or rules. |
| `attach_to_elb = true` | ALB, target group, listener, and listener rules are created (when their configs are provided). The ASG is automatically registered to the target group. |

## Auto-Wired Values

The module automatically handles these connections so you don't have to pass them manually:

- **ASG `launch_template`** — Automatically set from `module.launch_template.id` with `$Latest` version.
- **ASG `attach_target_groups`** — Automatically set to the target group ARN when `attach_to_elb = true` and `target_group` is defined.
- **ALB Listener `alb_arn`** — Automatically set from `module.alb.arn` if not explicitly provided.

## Outputs

| Output | Description |
|---|---|
| `launch_template_id` | ID of the launch template |
| `launch_template_name` | Name of the launch template |
| `alb_arn` | ARN of the ALB (null if `attach_to_elb = false`) |
| `alb_dns_name` | DNS name of the ALB |
| `alb_zone_id` | Route 53 zone ID of the ALB |
| `alb_name` | Name of the ALB |
| `target_group_arn` | ARN of the target group |
| `target_group_id` | ID of the target group |
| `alb_listener_arn` | ARN of the ALB listener |
| `alb_listener_id` | ID of the ALB listener |
| `alb_listener_rules` | Map of ALB listener rules with ARNs, IDs, priorities |
| `asg_name` | Name of the Auto Scaling group |
| `asg_arn` | ARN of the Auto Scaling group |
| `asg_id` | ID of the Auto Scaling group |
