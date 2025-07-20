#--------------------------------------------------------------------
# SSM Parameter Store Module
#--------------------------------------------------------------------

resource "aws_ssm_parameter" "parameter" {
  name        = var.ssm_parameter.name
  description = var.ssm_parameter.description
  type        = var.ssm_parameter.type
  value       = var.ssm_parameter.value
  tier        = var.ssm_parameter.tier
  overwrite   = var.ssm_parameter.overwrite

  tags = merge(var.common.tags,
    {
      Name = "${var.ssm_parameter.name}"
    }
  )

}
