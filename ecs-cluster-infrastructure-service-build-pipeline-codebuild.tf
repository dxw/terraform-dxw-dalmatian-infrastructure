resource "aws_iam_role" "infrastructure_ecs_cluster_service_codebuild" {
  for_each = local.infrastructure_ecs_cluster_services

  name        = "${local.resource_prefix}-${substr(sha512("ecs-service-codebuild-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-service-codebuild-${each.key}"

  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["codebuild.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_codebuild" {
  for_each = local.infrastructure_ecs_cluster_services

  name        = "${local.resource_prefix}-${substr(sha512("ecs-service-codepipeline-codebuild-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-service-codepipeline-codebuild-${each.key}"
  policy = templatefile(
    "${path.root}/policies/codebuild-default.json.tpl",
    { artifact_bucket_arn = aws_s3_bucket.infrastructure_ecs_cluster_service_build_pipeline_artifact_store[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_codebuild" {
  for_each = local.infrastructure_ecs_cluster_services

  role       = aws_iam_role.infrastructure_ecs_cluster_service_codebuild[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_codebuild[each.key].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_codebuild_blue_green" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["deployment_type"] == "blue-green"
  }

  name        = "${local.resource_prefix}-${substr(sha512("ecs-service-codepipeline-codebuild-blue-green-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-service-codepipeline-codebuild-blue-green-${each.key}"
  policy = templatefile(
    "${path.root}/policies/codebuild-ecs-blue-green.json.tpl", {}
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_codebuild_blue_green" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["deployment_type"] == "blue-green"
  }

  role       = aws_iam_role.infrastructure_ecs_cluster_service_codebuild[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_codebuild_blue_green[each.key].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_codebuild_kms_encrypt" {
  for_each = local.infrastructure_kms_encryption ? local.infrastructure_ecs_cluster_services : {}

  name        = "${local.resource_prefix}-${substr(sha512("ecs-service-codepipeline-codebuild-${each.key}-kms-encrypt"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-service-codepipeline-codebuild-${each.key}-kms-encrypt"
  policy = templatefile(
    "${path.root}/policies/kms-encrypt.json.tpl",
    { kms_key_arn = aws_kms_key.infrastructure[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_codebuild_kms_encrypt" {
  for_each = local.infrastructure_kms_encryption ? local.infrastructure_ecs_cluster_services : {}

  role       = aws_iam_role.infrastructure_ecs_cluster_service_codebuild[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_codebuild_kms_encrypt[each.key].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_codebuild_ecr_push" {
  for_each = local.infrastructure_ecs_cluster_services

  name        = "${local.resource_prefix}-${substr(sha512("ecs-service-codepipeline-codebuild-${each.key}-ecr-push"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-service-codepipeline-codebuild-${each.key}-ecr-push"
  policy = templatefile(
    "${path.root}/policies/ecr-push.json.tpl",
    { ecr_repository_arn = aws_ecr_repository.infrastructure_ecs_cluster_service[each.key].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_codebuild_ecr_push" {
  for_each = local.infrastructure_ecs_cluster_services

  role       = aws_iam_role.infrastructure_ecs_cluster_service_codebuild[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_codebuild_ecr_push[each.key].arn
}

resource "aws_codebuild_project" "infrastructure_ecs_cluster_service_build" {
  for_each = local.infrastructure_ecs_cluster_services

  name          = "${local.resource_prefix}-ecs-service-${each.key}"
  build_timeout = "60"
  service_role  = aws_iam_role.infrastructure_ecs_cluster_service_codebuild[each.key].arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.aws_account_id
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = each.key
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.infrastructure_ecs_cluster_service[each.key].name
    }

    environment_variable {
      name  = "REPOSITORY_URL"
      value = aws_ecr_repository.infrastructure_ecs_cluster_service[each.key].repository_url
    }

    dynamic "environment_variable" {
      for_each = local.infrastructure_dockerhub_username != "" ? [1] : []

      content {
        name  = "DOCKER_USERNAME"
        value = local.infrastructure_dockerhub_username
      }
    }

    dynamic "environment_variable" {
      for_each = local.infrastructure_dockerhub_token != "" ? [1] : []

      content {
        name  = "DOCKER_ACCESS_TOKEN"
        value = local.infrastructure_dockerhub_token
      }
    }

    dynamic "environment_variable" {
      for_each = each.value["deployment_type"] == "blue-green" ? [1] : []

      content {
        name  = "BLUE_GREEN"
        value = "true"
      }
    }

    dynamic "environment_variable" {
      for_each = each.value["deployment_type"] == "blue-green" ? [1] : []

      content {
        name  = "TASK_DEFINITION_FAMILY"
        value = aws_ecs_task_definition.infrastructure_ecs_cluster_service[each.key].family
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = each.value["buildspec_from_github_repo"] != null || each.value["buildspec_from_github_repo"] == true ? each.value["buildspec"] : data.aws_s3_object.ecs_cluster_service_buildspec[each.key].body
  }

  depends_on = [
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_codebuild,
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_codebuild_kms_encrypt,
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_codebuild_ecr_push,
  ]
}
