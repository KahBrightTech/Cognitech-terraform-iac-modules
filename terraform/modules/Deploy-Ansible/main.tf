#--------------------------------------------------------------------
# Data
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
# Creates a Launch Template for Ansible deployment if specified
#--------------------------------------------------------------------
module "launch_template" {
  source          = "../Launch_template"
  common          = var.common
  launch_template = var.deploy_ansible.launch_template
}

#--------------------------------------------------------------------
# Creates an ALB for Ansible deployment
#--------------------------------------------------------------------
module "alb" {
  count         = var.deploy_ansible.attach_to_elb && var.deploy_ansible.alb != null ? 1 : 0
  source        = "../Load-Balancers"
  common        = var.common
  load_balancer = var.deploy_ansible.alb
}

#--------------------------------------------------------------------
# Creates a Target Group for Ansible deployment
#--------------------------------------------------------------------
module "target_group" {
  count  = var.deploy_ansible.attach_to_elb && var.deploy_ansible.target_group != null ? 1 : 0
  source = "../Target-groups"
  common = var.common
  target_group = merge(
    var.deploy_ansible.target_group,
    {
      vpc_id = var.deploy_ansible.target_group.vpc_id
    }
  )
}

#--------------------------------------------------------------------
# Creates an ALB Listener for Ansible deployment
#--------------------------------------------------------------------
module "alb_listener" {
  count  = var.deploy_ansible.attach_to_elb && var.deploy_ansible.alb_listener != null ? 1 : 0
  source = "../alb-listeners"
  common = var.common
  alb_listener = merge(
    var.deploy_ansible.alb_listener,
    {
      alb_arn = var.deploy_ansible.alb_listener.alb_arn != null ? var.deploy_ansible.alb_listener.alb_arn : module.alb[0].arn
    }
  )
}

#--------------------------------------------------------------------
# Creates ALB Listener Rules for Ansible deployment
#--------------------------------------------------------------------
module "alb_listener_rule" {
  count  = var.deploy_ansible.attach_to_elb && var.deploy_ansible.alb_listener_rule != null ? 1 : 0
  source = "../alb-listener-rule"
  common = var.common
  rule   = var.deploy_ansible.alb_listener_rule
}

#--------------------------------------------------------------------
# Creates an Auto Scaling Group for Ansible deployment
#--------------------------------------------------------------------
module "asg" {
  source = "../AutoScaling"
  common = var.common
  Autoscaling_group = merge(
    var.deploy_ansible.asg,
    {
      launch_template = {
        id      = module.launch_template.id
        version = "$Latest"
      }
      attach_target_groups = var.deploy_ansible.attach_to_elb && var.deploy_ansible.target_group != null ? [module.target_group[0].target_group_arn] : var.deploy_ansible.asg.attach_target_groups
    }
  )
}