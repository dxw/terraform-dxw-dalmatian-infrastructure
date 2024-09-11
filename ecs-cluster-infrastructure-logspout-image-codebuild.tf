resource "aws_iam_role" "infrastructure_ecs_cluster_logspout_image_codebuild" {
  count = local.infrastructure_ecs_cluster_logspout_enabled ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-logspout-image-codebuild"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-logspout-image-codebuild"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["codebuild.amazonaws.com", "events.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_logspout_image_codebuild_cloudwatch_rw" {
  count = local.infrastructure_ecs_cluster_logspout_enabled ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-logspout-image-codebuild-cloudwatch-rw"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-logspout-image-codebuild-cloudwatch-rw"
  policy      = templatefile("${path.root}/policies/cloudwatch-logs-rw.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_logspout_image_codebuild_cloudwatch_rw" {
  count = local.infrastructure_ecs_cluster_logspout_enabled ? 1 : 0

  role       = aws_iam_role.infrastructure_ecs_cluster_logspout_image_codebuild[0].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_logspout_image_codebuild_cloudwatch_rw[0].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_logspout_image_codebuild_allow_builds" {
  count = local.infrastructure_ecs_cluster_logspout_enabled ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-logspout-image-codebuild-allow-builds"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-logspout-image-codebuild-allow-builds"
  policy      = templatefile("${path.root}/policies/codebuild-allow-builds.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_logspout_image_codebuild_allow_builds" {
  count = local.infrastructure_ecs_cluster_logspout_enabled ? 1 : 0

  role       = aws_iam_role.infrastructure_ecs_cluster_logspout_image_codebuild[0].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_logspout_image_codebuild_allow_builds[0].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_logspout_image_codebuild_ecr_push" {
  count = local.infrastructure_ecs_cluster_logspout_enabled ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-logspout-image-codebuild-ecr-push"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-logspout-image-codebuild-ecr-push"
  policy = templatefile(
    "${path.root}/policies/ecr-push.json.tpl",
    { ecr_repository_arn = aws_ecr_repository.infrastructure_ecs_cluster_logspout[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_logspout_image_codebuild_ecr_push" {
  count = local.infrastructure_ecs_cluster_logspout_enabled ? 1 : 0

  role       = aws_iam_role.infrastructure_ecs_cluster_logspout_image_codebuild[0].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_logspout_image_codebuild_ecr_push[0].arn
}

resource "aws_codebuild_project" "infrastructure_ecs_cluster_logspout_image_build" {
  count = local.infrastructure_ecs_cluster_logspout_enabled ? 1 : 0

  name          = "${local.resource_prefix}-ecs-cluster-logspout-image-build"
  description   = "${local.resource_prefix} ECS Cluster Logspout Image Build"
  build_timeout = "20"
  service_role  = aws_iam_role.infrastructure_ecs_cluster_logspout_image_codebuild[0].arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = local.aws_account_id
    }

    environment_variable {
      name  = "REPOSITORY_URI"
      value = aws_ecr_repository.infrastructure_ecs_cluster_logspout[0].repository_url
    }

    environment_variable {
      name  = "DOCKERHUB_USERNAME"
      value = local.infrastructure_dockerhub_username
    }

    environment_variable {
      name  = "DOCKERHUB_TOKEN"
      value = local.infrastructure_dockerhub_token
    }
  }

  source {
    type      = "NO_SOURCE"
    buildspec = templatefile("${path.root}/buildspecs/dalmatian-logspout.yml", {})
  }

  depends_on = [
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_logspout_image_codebuild_cloudwatch_rw,
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_logspout_image_codebuild_allow_builds,
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_logspout_image_codebuild_ecr_push,
  ]
}

resource "terraform_data" "infrastructure_ecs_cluster_logspout_image_build_trigger_codebuild" {
  count = local.infrastructure_ecs_cluster_logspout_enabled ? 1 : 0

  triggers_replace = [
    md5(templatefile("${path.root}/buildspecs/dalmatian-logspout.yml", {})),
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOF
      ${path.root}/local-exec-scripts/trigger-codedeploy-project.sh \
      -n "${aws_codebuild_project.infrastructure_ecs_cluster_logspout_image_build[0].name}"
    EOF
  }

  depends_on = [

  ]
}

resource "aws_cloudwatch_event_rule" "infrastructure_ecs_cluster_logspout_image_build_trigger_codebuild" {
  count = local.infrastructure_ecs_cluster_logspout_enabled ? 1 : 0

  name                = "${local.resource_prefix_hash}-ecs-cluster-logspout-image-build-trigger-codebuild"
  description         = "${local.resource_prefix} ECS Cluster Logspout Image Build Trigger CodeBuild"
  schedule_expression = "rate(24 hours)"
}

resource "aws_cloudwatch_event_target" "infrastructure_ecs_cluster_logspout_image_build_trigger_codebuild" {
  count = local.infrastructure_ecs_cluster_logspout_enabled ? 1 : 0

  target_id = "${local.resource_prefix_hash}-ecs-cluster-image-build-trigger-codebuild"
  rule      = aws_cloudwatch_event_rule.infrastructure_ecs_cluster_logspout_image_build_trigger_codebuild[0].name
  arn       = aws_codebuild_project.infrastructure_ecs_cluster_logspout_image_build[0].id
  role_arn  = aws_iam_role.infrastructure_ecs_cluster_logspout_image_codebuild[0].arn
}
