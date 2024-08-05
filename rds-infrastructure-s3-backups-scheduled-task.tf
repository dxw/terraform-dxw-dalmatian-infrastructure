resource "aws_iam_role" "infrastructure_rds_s3_backups_cloudwatch_schedule" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("rds-s3-backups-cloudwatch-schedule-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-rds-s3-backups-cloudwatch-schedule-${each.key}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["events.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_rds_s3_backups_cloudwatch_schedule_ecs_run_task" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("rds-s3-backups-cloudwatch-schedule-${each.key}-ecs-run-task"), 0, 6)}"
  description = "${local.resource_prefix}-rds-s3-backups-cloudwatch-schedule-${each.key}-ecs-run-task"
  policy      = templatefile("${path.root}/policies/ecs-run-task.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_rds_s3_backups_cloudwatch_schedule_ecs_run_task" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  role       = aws_iam_role.infrastructure_rds_s3_backups_cloudwatch_schedule[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_s3_backups_cloudwatch_schedule_ecs_run_task[each.key].arn
}

resource "aws_iam_policy" "infrastructure_rds_s3_backups_cloudwatch_schedule_pass_role" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("rds-s3-backups-cloudwatch-schedule-${each.key}-pass-role-execution-role"), 0, 6)}"
  description = "${local.resource_prefix}-rds-s3-backups-cloudwatch-schedule-${each.key}-pass-role-execution-role"
  policy = templatefile(
    "${path.root}/policies/pass-role.json.tpl",
    {
      role_arns = jsonencode([
        aws_iam_role.infrastructure_rds_s3_backups_task_execution[each.key].arn,
        aws_iam_role.infrastructure_rds_s3_backups_task[each.key].arn,
      ])
      services = jsonencode(["ecs-tasks.amazonaws.com"])
    }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_rds_s3_backups_cloudwatch_schedule_pass_role" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  role       = aws_iam_role.infrastructure_rds_s3_backups_cloudwatch_schedule[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_s3_backups_cloudwatch_schedule_pass_role[each.key].arn
}

resource "aws_cloudwatch_event_rule" "infrastructure_rds_s3_backups_scheduled_task" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  name                = "${local.resource_prefix}-rds-s3-backups-${each.key}"
  description         = "Run ${local.resource_prefix}-rds-s3-backups-${each.key} task at a scheduled time (${local.infrastructure_rds_backup_to_s3_cron_expression})"
  schedule_expression = local.infrastructure_rds_backup_to_s3_cron_expression
}

resource "aws_cloudwatch_event_target" "infrastructure_rds_s3_backups_scheduled_task" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  target_id = "${local.resource_prefix}-rds-s3-backups-${each.key}"
  rule      = aws_cloudwatch_event_rule.infrastructure_rds_s3_backups_scheduled_task[each.key].name
  arn       = aws_ecs_cluster.infrastrucutre_rds_tooling[0].arn
  role_arn  = aws_iam_role.infrastructure_rds_s3_backups_cloudwatch_schedule[each.key].arn
  input     = jsonencode({})

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.infrastructure_rds_s3_backups_scheduled_task[each.key].arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"
    propagate_tags      = "TASK_DEFINITION"

    network_configuration {
      subnets          = aws_db_subnet_group.infrastructure_rds[each.key].subnet_ids
      assign_public_ip = local.infrastructure_vpc_network_enable_private ? false : local.infrastructure_vpc_network_enable_public ? true : false
      security_groups = [
        aws_security_group.infrastructure_rds_s3_backups_scheduled_task[each.key].id,
      ]
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.infrastructure_rds_s3_backups_cloudwatch_schedule_ecs_run_task,
    aws_iam_role_policy_attachment.infrastructure_rds_s3_backups_cloudwatch_schedule_pass_role,
  ]
}
