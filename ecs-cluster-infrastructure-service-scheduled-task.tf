resource "aws_ecs_task_definition" "infrastructure_ecs_cluster_service_scheduled_task" {
  for_each = merge([
    for service_name, service in local.infrastructure_ecs_cluster_services : {
      for scheduled_task_name, scheduled_task in service["scheduled_tasks"] : "${service_name}_${scheduled_task_name}" => merge(
        scheduled_task,
        {
          container_name         = service_name
          extra_hosts            = service["container_extra_hosts"]
          volumes                = service["container_volumes"]
          enable_cloudwatch_logs = service["enable_cloudwatch_logs"]
        }
      )
    }
  ]...)

  family = "${local.resource_prefix}-${each.key}"
  container_definitions = templatefile(
    "./container-definitions/app.json.tpl",
    {
      container_name      = each.value["container_name"]
      image               = aws_ecr_repository.infrastructure_ecs_cluster_service[each.value["container_name"]].repository_url
      entrypoint          = each.value["entrypoint"] != null ? jsonencode(each.value["entrypoint"]) : "[]"
      environment_file_s3 = "${aws_s3_bucket.infrastructure_ecs_cluster_service_environment_files[0].arn}/${each.value["container_name"]}.env"
      environment         = jsonencode([])
      secrets             = jsonencode([])
      container_port      = 0
      extra_hosts = each.value["extra_hosts"] != null ? jsonencode([
        for extra_host in each.value["extra_hosts"] : {
          hostname  = extra_host.value["hostname"],
          ipAddress = extra_host.value["ip_address"]
        }
      ]) : "[]"
      volumes = each.value["volumes"] != null ? jsonencode([
        for volume in each.value["volumes"] : {
          sourceVolume  = volume.value["name"],
          containerPath = volume.value["container_path"]
        }
      ]) : "[]"
      linux_parameters = jsonencode({
        initProcessEnabled = false
      })
      cloudwatch_log_group  = each.value["enable_cloudwatch_logs"] == true ? aws_cloudwatch_log_group.infrastructure_ecs_cluster_service[each.value["container_name"]].name : ""
      awslogs_stream_prefix = ""
      region                = local.aws_region
    }
  )
  execution_role_arn       = aws_iam_role.infrastructure_ecs_cluster_service_task_execution[each.value["container_name"]].arn
  task_role_arn            = aws_iam_role.infrastructure_ecs_cluster_service_task[each.value["container_name"]].arn
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]

  dynamic "volume" {
    for_each = each.value["volumes"] != null ? each.value["volumes"] : []

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
  ]
}

resource "aws_cloudwatch_event_rule" "infrastructure_ecs_cluster_service_scheduled_task" {
  for_each = merge([
    for service_name, service in local.infrastructure_ecs_cluster_services : {
      for scheduled_task_name, scheduled_task in service["scheduled_tasks"] : "${service_name}_${scheduled_task_name}" => merge(
        scheduled_task,
        {
          scheduled_task_name = scheduled_task_name
          container_name      = service_name
        }
      )
    }
  ]...)

  name                = "${local.resource_prefix}-${each.value["container_name"]}-${each.value["scheduled_task_name"]}"
  description         = "Run ${local.resource_prefix}-${each.value["container_name"]}-${each.value["scheduled_task_name"]} task at a scheduled time (${each.value["schedule_expression"]})"
  schedule_expression = each.value["schedule_expression"]
}

resource "aws_iam_role" "infrastructure_ecs_cluster_service_scheduled_task" {
  for_each = merge([
    for service_name, service in local.infrastructure_ecs_cluster_services : {
      for scheduled_task_name, scheduled_task in service["scheduled_tasks"] : "${service_name}_${scheduled_task_name}" => merge(
        scheduled_task,
        {
          scheduled_task_name = scheduled_task_name
          container_name      = service_name
        }
      )
    }
  ]...)

  name        = "${local.resource_prefix}-${substr(sha512("${each.value["container_name"]}-${each.value["scheduled_task_name"]}-scheduled-task"), 0, 6)}"
  description = "${local.resource_prefix}-${each.value["container_name"]}-${each.value["scheduled_task_name"]}-scheduled-task"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["events.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_scheduled_task_pass_role_execution_role" {
  for_each = merge([
    for service_name, service in local.infrastructure_ecs_cluster_services : {
      for scheduled_task_name, scheduled_task in service["scheduled_tasks"] : "${service_name}_${scheduled_task_name}" => merge(
        scheduled_task,
        {
          scheduled_task_name = scheduled_task_name
          container_name      = service_name
        }
      )
    }
  ]...)

  name        = "${local.resource_prefix}-${substr(sha512("${each.value["container_name"]}-${each.value["scheduled_task_name"]}-scheduled-task-pass-role-execution-role"), 0, 6)}"
  description = "${local.resource_prefix}-${each.value["container_name"]}-${each.value["scheduled_task_name"]}-scheduled-task-pass-role-execution-role"
  policy = templatefile(
    "${path.root}/policies/pass-role.json.tpl",
    {
      role_arns = jsonencode([aws_iam_role.infrastructure_ecs_cluster_service_task_execution[each.value["container_name"]].arn])
      services  = jsonencode(["ecs-tasks.amazonaws.com"])
    }
  )
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_scheduled_task_ecs_run_task" {
  for_each = merge([
    for service_name, service in local.infrastructure_ecs_cluster_services : {
      for scheduled_task_name, scheduled_task in service["scheduled_tasks"] : "${service_name}_${scheduled_task_name}" => merge(
        scheduled_task,
        {
          scheduled_task_name = scheduled_task_name
          container_name      = service_name
        }
      )
    }
  ]...)

  name        = "${local.resource_prefix}-${substr(sha512("${each.value["container_name"]}-${each.value["scheduled_task_name"]}-scheduled-task-ecs-run-task"), 0, 6)}"
  description = "${local.resource_prefix}-${each.value["container_name"]}-${each.value["scheduled_task_name"]}-scheduled-task-ecs-run-task"
  policy      = templatefile("${path.root}/policies/ecs-run-task.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_scheduled_task_pass_role_execution_role" {
  for_each = merge([
    for service_name, service in local.infrastructure_ecs_cluster_services : {
      for scheduled_task_name, scheduled_task in service["scheduled_tasks"] : "${service_name}_${scheduled_task_name}" => scheduled_task
    }
  ]...)

  role       = aws_iam_role.infrastructure_ecs_cluster_service_scheduled_task[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_scheduled_task_pass_role_execution_role[each.key].arn
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_scheduled_task_ecs_run_task" {
  for_each = merge([
    for service_name, service in local.infrastructure_ecs_cluster_services : {
      for scheduled_task_name, scheduled_task in service["scheduled_tasks"] : "${service_name}_${scheduled_task_name}" => scheduled_task
    }
  ]...)

  role       = aws_iam_role.infrastructure_ecs_cluster_service_scheduled_task[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_scheduled_task_ecs_run_task[each.key].arn
}

resource "aws_cloudwatch_event_target" "infrastructure_ecs_cluster_service_scheduled_task" {
  for_each = merge([
    for service_name, service in local.infrastructure_ecs_cluster_services : {
      for scheduled_task_name, scheduled_task in service["scheduled_tasks"] : "${service_name}_${scheduled_task_name}" => merge(
        scheduled_task,
        {
          scheduled_task_name = scheduled_task_name
          container_name      = service_name
        }
      )
    }
  ]...)

  target_id = "${local.resource_prefix}-${each.value["container_name"]}-${each.value["scheduled_task_name"]}"
  rule      = aws_cloudwatch_event_rule.infrastructure_ecs_cluster_service_scheduled_task[each.key].name
  arn       = aws_ecs_cluster.infrastructure[0].arn
  role_arn  = aws_iam_role.infrastructure_ecs_cluster_service_scheduled_task[each.key].arn
  input     = jsonencode({})

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.infrastructure_ecs_cluster_service_scheduled_task[each.key].arn
  }
}
