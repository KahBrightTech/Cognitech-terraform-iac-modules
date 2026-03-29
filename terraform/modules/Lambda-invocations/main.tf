#--------------------------------------------------------------------
# Data
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#--------------------------------------------------------------------
# Creates permissions for services to invoke the Lambda function
#--------------------------------------------------------------------
resource "aws_lambda_permission" "this" {
  statement_id   = var.lambda-invocations.statement_id
  action         = "lambda:InvokeFunction"
  function_name  = var.lambda-invocations.function_name
  principal      = var.lambda-invocations.principal
  source_arn     = var.lambda-invocations.source_arn
  source_account = var.lambda-invocations.source_account
}