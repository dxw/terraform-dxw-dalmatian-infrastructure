resource "aws_ecr_repository" "infrastructure_ecs_cluster_service_sidecar" {
  for_each = local.infrastructure_ecs_cluster_service_sidecar_containers

  # Namespaced under the service's own repository name so it can never collide
  # with another service's application repository (`<prefix>-<service>`), which
  # a flat `<prefix>-<service>-<sidecar>` could for hyphenated service names.
  name = "${local.resource_prefix}-${each.value["service_name"]}/sidecar/${each.value["sidecar_name"]}"

  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  encryption_configuration {
    encryption_type = local.infrastructure_kms_encryption ? "KMS" : "AES256"
    kms_key         = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_task_execution_sidecar_ecr_pull" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if length(coalesce(v["sidecar_containers"], {})) > 0
  }

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-service-task-execution-${each.key}-sidecar-ecr-pull"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-service-task-execution-${each.key}-sidecar-ecr-pull"
  policy = templatefile(
    "${path.root}/policies/ecr-pull-multiple.json.tpl",
    {
      ecr_repository_arns = jsonencode([
        for sidecar_name in keys(each.value["sidecar_containers"]) : aws_ecr_repository.infrastructure_ecs_cluster_service_sidecar["${each.key}_${sidecar_name}"].arn
      ])
    }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_task_execution_sidecar_ecr_pull" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if length(coalesce(v["sidecar_containers"], {})) > 0
  }

  role       = aws_iam_role.infrastructure_ecs_cluster_service_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_task_execution_sidecar_ecr_pull[each.key].arn
}
