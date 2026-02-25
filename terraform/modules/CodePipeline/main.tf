#--------------------------------------------------------------------
# Data Sources
#--------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#--------------------------------------------------------------------
# S3 Bucket for CodePipeline Artifacts
#--------------------------------------------------------------------
resource "aws_s3_bucket" "artifacts" {
  count  = var.codepipeline != null ? 1 : 0
  bucket = "${var.common.account_name}-${var.common.region_prefix}-${var.codepipeline.artifact_bucket_name}"

  tags = merge(var.common.tags, {
    Name = "${var.common.account_name}-${var.common.region_prefix}-${var.codepipeline.artifact_bucket_name}"
  })
}

resource "aws_s3_bucket_versioning" "artifacts" {
  count  = var.codepipeline != null ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  count  = var.codepipeline != null ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  count  = var.codepipeline != null ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#--------------------------------------------------------------------
# IAM Role for CodePipeline
#--------------------------------------------------------------------
resource "aws_iam_role" "codepipeline" {
  count = var.codepipeline != null ? 1 : 0
  name  = "${var.common.account_name}-${var.common.region_prefix}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "codepipeline.amazonaws.com" }
    }]
  })

  tags = merge(var.common.tags, {
    Name = "${var.common.account_name}-${var.common.region_prefix}-codepipeline-role"
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  count = var.codepipeline != null ? 1 : 0
  name  = "${var.common.account_name}-${var.common.region_prefix}-codepipeline-policy"
  role  = aws_iam_role.codepipeline[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:ListTaskDefinitions",
          "ecs:DeregisterTaskDefinition"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:DescribeImages",
          "ecr:GetAuthorizationToken",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.artifacts[0].arn,
          "${aws_s3_bucket.artifacts[0].arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:GetDeploymentConfig",
          "ecs:RegisterTaskDefinition"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = "*"
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = [
              "ecs-tasks.amazonaws.com",
              "codedeploy.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

#--------------------------------------------------------------------
# IAM Role for CodeDeploy
#--------------------------------------------------------------------
resource "aws_iam_role" "codedeploy" {
  count = var.codepipeline != null ? 1 : 0
  name  = "${var.common.account_name}-${var.common.region_prefix}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" }
    }]
  })

  tags = merge(var.common.tags, {
    Name = "${var.common.account_name}-${var.common.region_prefix}-codedeploy-role"
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_ecs" {
  count      = var.codepipeline != null ? 1 : 0
  role       = aws_iam_role.codedeploy[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

#--------------------------------------------------------------------
# IAM Role for EventBridge
#--------------------------------------------------------------------
resource "aws_iam_role" "eventbridge" {
  count = var.codepipeline != null ? 1 : 0
  name  = "${var.common.account_name}-${var.common.region_prefix}-eventbridge-pipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
    }]
  })

  tags = merge(var.common.tags, {
    Name = "${var.common.account_name}-${var.common.region_prefix}-eventbridge-pipeline-role"
  })
}

resource "aws_iam_role_policy" "eventbridge" {
  count = var.codepipeline != null ? 1 : 0
  name  = "${var.common.account_name}-${var.common.region_prefix}-eventbridge-pipeline-policy"
  role  = aws_iam_role.eventbridge[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["codepipeline:StartPipelineExecution"]
      Resource = [
        for pipeline in aws_codepipeline.this : pipeline.arn
      ]
    }]
  })
}

#--------------------------------------------------------------------
# CodeDeploy Application
#--------------------------------------------------------------------
resource "aws_codedeploy_app" "this" {
  for_each         = var.codepipeline != null ? { for p in var.codepipeline.pipelines : p.name => p } : {}
  name             = "${var.common.account_name}-${var.common.region_prefix}-${each.value.name}-app"
  compute_platform = "ECS"

  tags = merge(var.common.tags, {
    Name = "${var.common.account_name}-${var.common.region_prefix}-${each.value.name}-app"
  })
}

#--------------------------------------------------------------------
# CodeDeploy Deployment Group
#--------------------------------------------------------------------
resource "aws_codedeploy_deployment_group" "this" {
  for_each               = var.codepipeline != null ? { for p in var.codepipeline.pipelines : p.name => p } : {}
  app_name               = aws_codedeploy_app.this[each.key].name
  deployment_group_name  = "${var.common.account_name}-${var.common.region_prefix}-${each.value.name}-dg"
  service_role_arn       = aws_iam_role.codedeploy[0].arn
  deployment_config_name = each.value.deployment_config != null ? each.value.deployment_config : "CodeDeployDefault.ECSAllAtOnce"

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = each.value.termination_wait_time != null ? each.value.termination_wait_time : 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = each.value.ecs_cluster_name
    service_name = each.value.ecs_service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = each.value.listener_arns
      }
      target_group {
        name = each.value.target_group_1_name
      }
      target_group {
        name = each.value.target_group_2_name
      }
    }
  }

  tags = merge(var.common.tags, {
    Name = "${var.common.account_name}-${var.common.region_prefix}-${each.value.name}-dg"
  })
}

#--------------------------------------------------------------------
# CodePipeline
#--------------------------------------------------------------------
resource "aws_codepipeline" "this" {
  for_each = var.codepipeline != null ? { for p in var.codepipeline.pipelines : p.name => p } : {}
  name     = "${var.common.account_name}-${var.common.region_prefix}-${each.value.name}-pipeline"
  role_arn = aws_iam_role.codepipeline[0].arn

  artifact_store {
    location = aws_s3_bucket.artifacts[0].bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "ECR-Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        RepositoryName = each.value.ecr_repository_name
        ImageTag       = each.value.ecr_image_tag
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "ECS-Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
      input_artifacts = ["source_output"]
      configuration = {
        ApplicationName                = aws_codedeploy_app.this[each.key].name
        DeploymentGroupName            = aws_codedeploy_deployment_group.this[each.key].deployment_group_name
        TaskDefinitionTemplateArtifact = "source_output"
        AppSpecTemplateArtifact        = "source_output"
      }
    }
  }

  tags = merge(var.common.tags, {
    Name = "${var.common.account_name}-${var.common.region_prefix}-${each.value.name}-pipeline"
  })
}

#--------------------------------------------------------------------
# EventBridge Rules - Trigger pipeline on ECR push
#--------------------------------------------------------------------
resource "aws_cloudwatch_event_rule" "ecr_push" {
  for_each = var.codepipeline != null ? { for p in var.codepipeline.pipelines : p.name => p } : {}
  name     = "${var.common.account_name}-${var.common.region_prefix}-${each.value.name}-ecr-push"

  event_pattern = jsonencode({
    source      = ["aws.ecr"]
    detail-type = ["ECR Image Action"]
    detail = {
      action-type     = ["PUSH"]
      result          = ["SUCCESS"]
      repository-name = [each.value.ecr_repository_name]
      image-tag       = [each.value.ecr_image_tag]
    }
  })

  tags = merge(var.common.tags, {
    Name = "${var.common.account_name}-${var.common.region_prefix}-${each.value.name}-ecr-push"
  })
}

resource "aws_cloudwatch_event_target" "pipeline" {
  for_each = var.codepipeline != null ? { for p in var.codepipeline.pipelines : p.name => p } : {}
  rule     = aws_cloudwatch_event_rule.ecr_push[each.key].name
  arn      = aws_codepipeline.this[each.key].arn
  role_arn = aws_iam_role.eventbridge[0].arn
}
