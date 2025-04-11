resource "aws_iam_role" "infrastructure_s3_to_azure_backup_cloudwatch_schedule" {
  count = local.infrastructure_s3_to_azure_backup_cron_expression != "" ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("s3-to-azure-backup-cloudwatch-schedule"), 0, 6)}"
  description = "${local.resource_prefix}-s3-to-azure-backup-cloudwatch-schedule"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["events.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_s3_to_azure_backup_cloudwatch_schedule_ecs_run_task" {
  count = local.infrastructure_s3_to_azure_backup_cron_expression != "" ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("s3-to-azure-backup-cloudwatch-schedule-ecs-run-task"), 0, 6)}"
  description = "${local.resource_prefix}-s3-to-azure-backup-cloudwatch-schedule-ecs-run-task"
  policy      = templatefile("${path.root}/policies/ecs-run-task.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_s3_to_azure_backup_cloudwatch_schedule_ecs_run_task" {
  count = local.infrastructure_s3_to_azure_backup_cron_expression != "" ? 1 : 0

  role       = aws_iam_role.infrastructure_s3_to_azure_backup_cloudwatch_schedule[0].name
  policy_arn = aws_iam_policy.infrastructure_s3_to_azure_backup_cloudwatch_schedule_ecs_run_task[0].arn
}

resource "aws_iam_policy" "infrastructure_s3_to_azure_backup_cloudwatch_schedule_pass_role_tooling_task_roles" {
  count = local.infrastructure_s3_to_azure_backup_cron_expression != "" ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("s3-to-azure-backup-cloudwatch-schedule-pass-role-tooling-task-roles"), 0, 6)}"
  description = "${local.resource_prefix}-s3-to-azure-backup-cloudwatch-schedule-pass-role-tooling-task-roles"
  policy = templatefile(
    "${path.root}/policies/pass-role.json.tpl",
    {
      role_arns = jsonencode([
        aws_iam_role.infrastructure_rds_tooling_task_execution[0].arn,
        aws_iam_role.infrastructure_rds_tooling_task[0].arn,
      ])
      services = jsonencode(["ecs-tasks.amazonaws.com"])
    }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_s3_to_azure_backup_cloudwatch_schedule_pass_role_tooling_task_roles" {
  count = local.infrastructure_s3_to_azure_backup_cron_expression != "" ? 1 : 0

  role       = aws_iam_role.infrastructure_s3_to_azure_backup_cloudwatch_schedule[0].name
  policy_arn = aws_iam_policy.infrastructure_s3_to_azure_backup_cloudwatch_schedule_pass_role_tooling_task_roles[0].arn
}

resource "aws_cloudwatch_event_rule" "infrastructure_s3_to_azure_backup_scheduled_task" {
  count = local.infrastructure_s3_to_azure_backup_cron_expression != "" ? 1 : 0

  name                = "${local.resource_prefix}-s3-to-azure-backup"
  description         = "Run ${local.resource_prefix}-s3-to-azure-backup task at a scheduled time (${local.infrastructure_s3_to_azure_backup_cron_expression})"
  schedule_expression = local.infrastructure_s3_to_azure_backup_cron_expression
}

resource "aws_cloudwatch_event_target" "infrastructure_s3_to_azure_backup_scheduled_task" {
  count = local.infrastructure_s3_to_azure_backup_cron_expression != "" ? 1 : 0

  target_id = "${local.resource_prefix}-s3-to-azure-backup"
  rule      = aws_cloudwatch_event_rule.infrastructure_s3_to_azure_backup_scheduled_task[0].name
  arn       = aws_ecs_cluster.infrastrucutre_rds_tooling[0].arn
  role_arn  = aws_iam_role.infrastructure_s3_to_azure_backup_cloudwatch_schedule[0].arn
  input = jsonencode({
    containerOverrides = [
      {
        name                  = "rds-tooling-s3toazurebackup",
        command               = ["/bin/bash", "-c", local.infrastructure_s3_to_azure_backup_command]
        awslogs_stream_prefix = "${local.resource_prefix}-s3-to-azure-backup-s3toazurebackup"
      }
    ]
  })

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.infrastructure_rds_tooling["s3toazurebackup"].arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"
    propagate_tags      = "TASK_DEFINITION"

    network_configuration {
      subnets          = aws_db_subnet_group.infrastructure_rds[each.key].subnet_ids
      assign_public_ip = local.infrastructure_vpc_network_enable_private ? false : local.infrastructure_vpc_network_enable_public ? true : false
      security_groups = [
        aws_security_group.infrastructure_rds_tooling[each.key].id,
      ]
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.infrastructure_rds_s3_backups_cloudwatch_schedule_ecs_run_task,
    aws_iam_role_policy_attachment.infrastructure_rds_s3_backups_cloudwatch_schedule_pass_role_tooling_task_roles,
  ]
}
