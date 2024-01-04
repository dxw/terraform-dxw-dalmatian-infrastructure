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

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_codebuild_kms_decrypt" {
  for_each = local.infrastructure_kms_encryption ? local.infrastructure_ecs_cluster_services : {}

  name        = "${local.resource_prefix}-${substr(sha512("ecs-service-codepipeline-codebuild-${each.key}-kms-decrypt"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-service-codepipeline-codebuild-${each.key}-kms-decrypt"
  policy = templatefile(
    "${path.root}/policies/kms-decrypt.json.tpl",
    { kms_key_arn = aws_kms_key.infrastructure[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_codebuild_kms_decrypt" {
  for_each = local.infrastructure_kms_encryption ? local.infrastructure_ecs_cluster_services : {}

  role       = aws_iam_role.infrastructure_ecs_cluster_service_codebuild[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_codebuild_kms_decrypt[each.key].arn
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
  }

  source {
    type = "CODEPIPELINE"
  }
}
