resource "aws_cloudwatch_log_group" "infrastructure_ecs_cluster_service" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["enable_cloudwatch_logs"] == true
  }

  name              = "${local.resource_prefix}-infrastructure-ecs-cluster-service-logs-${each.key}"
  retention_in_days = each.value["cloudwatch_logs_retention"]
  kms_key_id        = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  skip_destroy      = true
}

resource "aws_iam_role" "infrastructure_ecs_cluster_service_task_execution" {
  for_each = local.infrastructure_ecs_cluster_services

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-service-task-execution-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-service-task-execution-${each.key}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_task_execution_ecr_pull" {
  for_each = local.infrastructure_ecs_cluster_services

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-service-task-execution-${each.key}-ecr-pull"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-service-task-execution-${each.key}-ecr-pull"
  policy = templatefile(
    "${path.root}/policies/ecr-pull.json.tpl",
    { ecr_repository_arn = aws_ecr_repository.infrastructure_ecs_cluster_service[each.key].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_task_execution_ecr_pull" {
  for_each = local.infrastructure_ecs_cluster_services

  role       = aws_iam_role.infrastructure_ecs_cluster_service_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_task_execution_ecr_pull[each.key].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_task_execution_cloudwatch_logs" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["enable_cloudwatch_logs"] == true
  }

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-service-task-execution-${each.key}-cloudwatch-logs"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-service-task-execution-${each.key}-cloudwatch-logs"
  policy      = templatefile("${path.root}/policies/cloudwatch-logs-rw.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_task_execution_cloudwatch_logs" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["enable_cloudwatch_logs"] == true
  }

  role       = aws_iam_role.infrastructure_ecs_cluster_service_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_task_execution_cloudwatch_logs[each.key].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_task_execution_s3_read_envfiles" {
  for_each = local.infrastructure_ecs_cluster_services

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-service-task-execution-${each.key}-s3-read-envfiles"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-service-task-execution-${each.key}-s3-read-envfiles"
  policy = templatefile("${path.root}/policies/s3-object-read.json.tpl", {
    bucket_arn = aws_s3_bucket.infrastructure_ecs_cluster_service_environment_files[0].arn
  })
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_task_execution_s3_read_envfiles" {
  for_each = local.infrastructure_ecs_cluster_services

  role       = aws_iam_role.infrastructure_ecs_cluster_service_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_task_execution_s3_read_envfiles[each.key].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_task_execution_kms_decrypt" {
  for_each = local.infrastructure_kms_encryption ? local.infrastructure_ecs_cluster_services : {}

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-service-task-execution-${each.key}-kms-decrypt"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-service-task-execution-${each.key}-kms-decrypt"
  policy = templatefile(
    "${path.root}/policies/kms-decrypt.json.tpl",
    { kms_key_arn = aws_kms_key.infrastructure[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_task_execution_kms_decrypt" {
  for_each = local.infrastructure_kms_encryption ? local.infrastructure_ecs_cluster_services : {}

  role       = aws_iam_role.infrastructure_ecs_cluster_service_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_task_execution_kms_decrypt[each.key].arn
}

resource "aws_iam_role" "infrastructure_ecs_cluster_service_task" {
  for_each = local.infrastructure_ecs_cluster_services

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-service-task-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-service-task-${each.key}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_task_ssm_create_channels" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["enable_execute_command"] == true
  }

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-service-task-${each.key}-create-channels"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-service-task-${each.key}-create-channels"
  policy      = templatefile("${path.root}/policies/ssm-create-channels.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_task_ssm_create_channels" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["enable_execute_command"] == true
  }

  role       = aws_iam_role.infrastructure_ecs_cluster_service_task[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_task_ssm_create_channels[each.key].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_task_custom" {
  for_each = merge([
    for service_name, service in local.infrastructure_ecs_cluster_services : {
      for custom_policy_name, custom_policy in service["custom_policies"] : "${service_name}_${custom_policy_name}" => {
        custom_policy      = custom_policy
        service_name       = service_name
        custom_policy_name = custom_policy_name
      }
    }
  ]...)

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-service-task-execution-${each.value["service_name"]}-custom-${each.value["custom_policy_name"]}"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-service-task-execution-${each.value["service_name"]}-custom-${each.value["custom_policy_name"]} ${each.value["custom_policy"]["description"]}"
  policy      = jsonencode(each.value["custom_policy"]["policy"])
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_task_custom" {
  for_each = merge([
    for service_name, service in local.infrastructure_ecs_cluster_services : {
      for custom_policy_name, custom_policy in service["custom_policies"] : "${service_name}_${custom_policy_name}" => {
        service_name = service_name
      }
    }
  ]...)

  role       = aws_iam_role.infrastructure_ecs_cluster_service_task[each.value["service_name"]].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_task_custom[each.key].arn
}

resource "aws_ecs_task_definition" "infrastructure_ecs_cluster_service" {
  for_each = local.infrastructure_ecs_cluster_services

  family = "${local.resource_prefix}-${each.key}"
  container_definitions = templatefile(
    "./container-definitions/app.json.tpl",
    {
      container_name      = each.key
      image               = aws_ecr_repository.infrastructure_ecs_cluster_service[each.key].repository_url
      entrypoint          = each.value["container_entrypoint"] != null ? jsonencode(each.value["container_entrypoint"]) : "[]"
      environment_file_s3 = "${aws_s3_bucket.infrastructure_ecs_cluster_service_environment_files[0].arn}/${each.key}.env"
      container_port      = each.value["container_port"] != null ? each.value["container_port"] : 0
      extra_hosts = each.value["container_extra_hosts"] != null ? jsonencode([
        for extra_host in each.value["container_extra_hosts"] : {
          hostname  = extra_host["hostname"],
          ipAddress = extra_host["ip_address"]
        }
      ]) : "[]"
      volumes = each.value["container_volumes"] != null ? jsonencode([
        for volume in each.value["container_volumes"] : {
          sourceVolume  = volume["name"],
          containerPath = volume["container_path"]
        }
      ]) : "[]"
      linux_parameters = each.value["enable_execute_command"] == true ? jsonencode({
        initProcessEnabled = true
      }) : "{}"
      cloudwatch_log_group = each.value["enable_cloudwatch_logs"] == true ? aws_cloudwatch_log_group.infrastructure_ecs_cluster_service[each.key].name : ""
      region               = local.aws_region
    }
  )
  execution_role_arn       = aws_iam_role.infrastructure_ecs_cluster_service_task_execution[each.key].arn
  task_role_arn            = aws_iam_role.infrastructure_ecs_cluster_service_task[each.key].arn
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]

  dynamic "volume" {
    for_each = each.value["container_volumes"] != null ? each.value["container_volumes"] : []

    content {
      name      = volume.value["name"]
      host_path = volume.value["host_path"]
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_task_execution_ecr_pull,
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_task_execution_cloudwatch_logs,
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_task_execution_s3_read_envfiles,
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_task_execution_kms_decrypt,
    aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_task_ssm_create_channels,
  ]
}

resource "aws_ecs_service" "infrastructure_ecs_cluster_service" {
  for_each = local.infrastructure_ecs_cluster_services

  name            = each.key
  cluster         = aws_ecs_cluster.infrastructure[0].name
  task_definition = aws_ecs_task_definition.infrastructure_ecs_cluster_service[each.key].arn
  desired_count   = each.value["container_count"]

  deployment_minimum_healthy_percent = 50

  enable_execute_command = each.value["enable_execute_command"]

  deployment_controller {
    type = each.value["deployment_type"] == "rolling" ? "ECS" : each.value["deployment_type"] == "blue-green" ? "CODE_DEPLOY" : null
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  dynamic "load_balancer" {
    for_each = (each.value["deployment_type"] == "rolling" || each.value["deployment_type"] == "blue-green") && each.value["container_port"] != 0 ? [1] : []

    content {
      target_group_arn = each.value["deployment_type"] == "rolling" ? aws_alb_target_group.infrastructure_ecs_cluster_service[each.key].arn : each.value["deployment_type"] == "blue-green" ? aws_alb_target_group.infrastructure_ecs_cluster_service_blue[each.key].arn : null
      container_name   = each.key
      container_port   = each.value["container_port"]
    }
  }

  health_check_grace_period_seconds = each.value["container_port"] != 0 ? each.value["container_heath_grace_period"] : null

  launch_type = "EC2"

  depends_on = [
    aws_alb_listener.infrastructure_ecs_cluster_service_http_https_redirect,
    aws_alb_listener.infrastructure_ecs_cluster_service_http,
    aws_alb_listener.infrastructure_ecs_cluster_service_https,
  ]

  lifecycle {
    ignore_changes = [
      load_balancer,
      task_definition,
    ]
  }
}
