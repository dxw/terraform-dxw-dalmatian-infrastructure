resource "aws_iam_role" "infrastructure_ecs_cluster_service_codepipeline" {
  for_each = local.infrastructure_ecs_cluster_services

  name        = "${local.resource_prefix}-${substr(sha512("ecs-service-codepipeline-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-service-codepipeline-${each.key}"

  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["codepipeline.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_codepipeline" {
  for_each = local.infrastructure_ecs_cluster_services

  name        = "${local.resource_prefix}-${substr(sha512("ecs-service-codepipeline-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-service-codepipeline-${each.key}"
  policy = templatefile(
    "${path.root}/policies/codepipeline-default.json.tpl",
    { artifact_bucket_arn = aws_s3_bucket.infrastructure_ecs_cluster_service_build_pipeline_artifact_store[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_codepipeline" {
  for_each = local.infrastructure_ecs_cluster_services

  role       = aws_iam_role.infrastructure_ecs_cluster_service_codepipeline[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_codepipeline[each.key].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_codepipeline_kms_encrypt" {
  for_each = local.infrastructure_kms_encryption ? local.infrastructure_ecs_cluster_services : {}

  name        = "${local.resource_prefix}-${substr(sha512("ecs-service-codepipeline-${each.key}-kms-encrypt"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-service-codepipeline-${each.key}-kms-encrypt"
  policy = templatefile(
    "${path.root}/policies/kms-encrypt.json.tpl",
    { kms_key_arn = aws_kms_key.infrastructure[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_codepipeline_kms_encrypt" {
  for_each = local.infrastructure_kms_encryption ? local.infrastructure_ecs_cluster_services : {}

  role       = aws_iam_role.infrastructure_ecs_cluster_service_codepipeline[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_codepipeline_kms_encrypt[each.key].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_codepipeline_codestar_connection" {
  for_each = { for k, v in local.infrastructure_ecs_cluster_services : k => v if v["github_v1_source"] != true }

  name        = "${local.resource_prefix}-${substr(sha512("ecs-service-codepipeline-${each.key}-codestar-connection"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-service-codepipeline-${each.key}-codestar-connection"
  policy = templatefile(
    "${path.root}/policies/codestar-connection-use.json.tpl",
    { codestar_connection_arn = each.value["codestar_connection_arn"] }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_codepipeline_codestar_connection" {
  for_each = { for k, v in local.infrastructure_ecs_cluster_services : k => v if v["github_v1_source"] != true }

  role       = aws_iam_role.infrastructure_ecs_cluster_service_codepipeline[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_codepipeline_codestar_connection[each.key].arn
}

resource "aws_codepipeline" "infrastructure_ecs_cluster_service" {
  for_each = local.infrastructure_ecs_cluster_services

  name = "${local.resource_prefix}-ecs-service-${each.key}"

  role_arn = aws_iam_role.infrastructure_ecs_cluster_service_codepipeline[each.key].arn

  artifact_store {
    location = aws_s3_bucket.infrastructure_ecs_cluster_service_build_pipeline_artifact_store[0].bucket
    type     = "S3"

    dynamic "encryption_key" {
      for_each = local.infrastructure_kms_encryption ? [1] : []

      content {
        id   = aws_kms_key.infrastructure[0].arn
        type = "KMS"
      }
    }
  }

  dynamic "stage" {
    for_each = each.value["github_v1_source"] == true ? [1] : []

    content {
      name = "Source"

      action {
        name             = "Source"
        category         = "Source"
        owner            = "ThirdParty"
        provider         = "GitHub"
        version          = "1"
        output_artifacts = ["source"]

        configuration = {
          Owner      = each.value["github_owner"]
          Repo       = each.value["github_repo"]
          Branch     = each.value["github_track_revision"]
          OAuthToken = each.value["github_v1_oauth_token"]
        }
      }
    }
  }

  dynamic "stage" {
    for_each = each.value["github_v1_source"] == true ? [] : [1]

    content {
      name = "Source"

      action {
        name             = "Source"
        category         = "Source"
        owner            = "AWS"
        provider         = "CodeStarSourceConnection"
        version          = "1"
        output_artifacts = ["source"]

        configuration = {
          ConnectionArn    = each.value["codestar_connection_arn"]
          FullRepositoryId = "${each.value["github_owner"]}/${each.value["github_repo"]}"
          BranchName       = each.value["github_track_revision"]
        }
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source"]

      configuration = {
        ProjectName = aws_codebuild_project.infrastructure_ecs_cluster_service_build[each.key].name
      }
    }
  }
}
