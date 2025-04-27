#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#--------------------------------------------------------------------
# Creates Lambda execution role
#--------------------------------------------------------------------
resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.common.account_name}-${var.common.region_prefix}-${var.Lambda.function_name}-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

#--------------------------------------------------------------------
# Creates IAM policy for Lambda execution role
#--------------------------------------------------------------------
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.common.account_name}-${var.common.region_prefix}-${var.Lambda.function_name}-exec-role-policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StartInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.common.account_name}-${var.common.region_prefix}-${var.Lambda.function_name}:*"
      }
    ]
  })
}
#--------------------------------------------------------------------
#  Creates Cloudwatch log group for Lambda function
#--------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.common.account_name}-${var.common.region_prefix}-${var.Lambda.function_name}"
  retention_in_days = 14
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.Lambda.function_name}"
    }
  )
}

#--------------------------------------------------------------------
# Creates lambda layers 
#--------------------------------------------------------------------
resource "aws_lambda_layer_version" "default" {
  layer_name          = "${var.common.account_name}-${var.common.region_prefix}-${var.Lambda.function_name}-layer"
  compatible_runtimes = [var.Lambda.runtime]
  description         = var.Lambda.layer_description
  s3_bucket           = var.Lambda.private_bucklet_name
  s3_key              = var.Lambda.layer_s3_key

}

#--------------------------------------------------------------------
# Creates Lambda function
#--------------------------------------------------------------------
resource "aws_lambda_function" "lambda_function" {
  function_name = "${var.common.account_name}-${var.common.region_prefix}-${var.Lambda.function_name}"
  description   = var.Lambda.description
  handler       = var.Lambda.handler
  runtime       = var.Lambda.runtime
  role          = aws_iam_role.lambda_exec_role.arn
  timeout       = var.Lambda.timeout

  s3_bucket = var.Lambda.private_bucklet_name
  s3_key    = var.Lambda.lamda_s3_key
  layers    = [aws_lambda_layer_version.default.arn]
  tags = merge(var.common.tags,
    {
      Name = "${var.common.account_name}-${var.common.region_prefix}-${var.Lambda.function_name}"
    }
  )
}

#--------------------------------------------------------------------
# Creates permission for cloudformation to invoke the Lambda function
#--------------------------------------------------------------------
resource "aws_lambda_permission" "allow_cloudformation" {
  statement_id   = "AllowExecutionFromCloudFormation"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.lambda_function.function_name
  principal      = "cloudformation.amazonaws.com"
  source_account = data.aws_caller_identity.current.account_id
}
