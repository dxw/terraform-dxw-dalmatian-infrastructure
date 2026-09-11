resource "aws_iam_role" "infrastructure_ecs_cluster_service_sidecar_image_codebuild" {
  for_each = local.infrastructure_ecs_cluster_service_sidecar_containers

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-service-sidecar-${each.key}-image-codebuild"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-service-${each.value["service_name"]}-sidecar-${each.value["sidecar_name"]}-image-codebuild"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["codebuild.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_sidecar_image_codebuild_cloudwatch_rw" {
  for_each = local.infrastructure_ecs_cluster_service_sidecar_containers

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-service-sidecar-${each.key}-image-codebuild-cloudwatch-rw"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-service-${each.value["service_name"]}-sidecar-${each.value["sidecar_name"]}-image-codebuild-cloudwatch-rw"
  policy      = templatefile("${path.root}/policies/cloudwatch-logs-rw.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_sidecar_image_codebuild_cloudwatch_rw" {
  for_each = local.infrastructure_ecs_cluster_service_sidecar_containers

  role       = aws_iam_role.infrastructure_ecs_cluster_service_sidecar_image_codebuild[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_sidecar_image_codebuild_cloudwatch_rw[each.key].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_sidecar_image_codebuild_ecr_push" {
  for_each = local.infrastructure_ecs_cluster_service_sidecar_containers

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-service-sidecar-${each.key}-image-codebuild-ecr-push"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-service-${each.value["service_name"]}-sidecar-${each.value["sidecar_name"]}-image-codebuild-ecr-push"
  policy = templatefile(
    "${path.root}/policies/ecr-push.json.tpl",
    { ecr_repository_arn = aws_ecr_repository.infrastructure_ecs_cluster_service_sidecar[each.key].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_sidecar_image_codebuild_ecr_push" {
  for_each = local.infrastructure_ecs_cluster_service_sidecar_containers

  role       = aws_iam_role.infrastructure_ecs_cluster_service_sidecar_image_codebuild[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_sidecar_image_codebuild_ecr_push[each.key].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_sidecar_image_codebuild_ecr_describe" {
  for_each = local.infrastructure_ecs_cluster_service_sidecar_containers

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-service-sidecar-${each.key}-image-codebuild-ecr-describe"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-service-${each.value["service_name"]}-sidecar-${each.value["sidecar_name"]}-image-codebuild-ecr-describe"
  policy = templatefile(
    "${path.root}/policies/ecr-describe-images.json.tpl",
    { ecr_repository_arn = aws_ecr_repository.infrastructure_ecs_cluster_service_sidecar[each.key].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_sidecar_image_codebuild_ecr_describe" {
  for_each = local.infrastructure_ecs_cluster_service_sidecar_containers

  role       = aws_iam_role.infrastructure_ecs_cluster_service_sidecar_image_codebuild[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_sidecar_image_codebuild_ecr_describe[each.key].arn
}

resource "aws_codebuild_project" "infrastructure_ecs_cluster_service_sidecar_image_mirror" {
  for_each = local.infrastructure_ecs_cluster_service_sidecar_containers

  # each.key is `<service>_<sidecar>`; names cannot contain `_`, so it is the
  # one unambiguous form for AWS names that do not allow `/`.
  name          = "${local.resource_prefix}-ecs-cluster-service-sidecar-${each.key}-image-mirror"
  description   = "${local.resource_prefix} ECS Cluster Service ${each.value["service_name"]} sidecar ${each.value["sidecar_name"]} image mirror"
  build_timeout = "20"
  service_role  = aws_iam_role.infrastructure_ecs_cluster_service_sidecar_image_codebuild[each.key].arn

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
      value = aws_ecr_repository.infrastructure_ecs_cluster_service_sidecar[each.key].repository_url
    }

    environment_variable {
      name  = "REPOSITORY_NAME"
      value = aws_ecr_repository.infrastructure_ecs_cluster_service_sidecar[each.key].name
    }

    environment_variable {
      name  = "SOURCE_IMAGE"
      value = each.value["image"]
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = each.value["image_tag"]
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
    buildspec = templatefile("${path.root}/buildspecs/dalmatian-sidecar-mirror.yml", {})
  }

  depends_on = [
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_sidecar_image_codebuild_cloudwatch_rw,
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_sidecar_image_codebuild_ecr_push,
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_sidecar_image_codebuild_ecr_describe,
  ]
}

# Mirrors the pinned image on creation and again whenever the digest changes,
# so the task definition never references a tag that is not yet in ECR.
resource "terraform_data" "infrastructure_ecs_cluster_service_sidecar_image_mirror_trigger_codebuild" {
  for_each = local.infrastructure_ecs_cluster_service_sidecar_containers

  triggers_replace = [
    each.value["image"],
    aws_ecr_repository.infrastructure_ecs_cluster_service_sidecar[each.key].repository_url,
    md5(templatefile("${path.root}/buildspecs/dalmatian-sidecar-mirror.yml", {})),
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOF
      ${path.root}/local-exec-scripts/trigger-codedeploy-project.sh \
      -n "${aws_codebuild_project.infrastructure_ecs_cluster_service_sidecar_image_mirror[each.key].name}"
    EOF
  }
}
