resource "aws_iam_role" "infrastructure_rds_utility_task_execution" {
  for_each = local.infrastructure_rds

  name        = "${local.resource_prefix}-${substr(sha512("rds-utility-task-execution-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-rds-utility-task-execution-${each.key}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_rds_utility_task_execution_ecr_pull" {
  for_each = local.infrastructure_rds

  name        = "${local.resource_prefix}-${substr(sha512("rds-utility-task-execution-${each.key}-ecr-pull"), 0, 6)}"
  description = "${local.resource_prefix}-rds-utility-task-execution-${each.key}-ecr-pull"
  policy = templatefile(
    "${path.root}/policies/ecr-pull.json.tpl",
    { ecr_repository_arn = aws_ecr_repository.infrastructure_rds_s3_backups[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_rds_utility_task_execution_ecr_pull" {
  for_each = local.infrastructure_rds

  role       = aws_iam_role.infrastructure_rds_utility_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_utility_task_execution_ecr_pull[each.key].arn
}

resource "aws_iam_policy" "infrastructure_rds_utility_task_execution_cloudwatch_logs" {
  for_each = local.infrastructure_rds

  name        = "${local.resource_prefix}-${substr(sha512("rds-utility-task-execution-${each.key}-cloudwatch-logs"), 0, 6)}"
  description = "${local.resource_prefix}-rds-utility-task-execution-${each.key}-cloudwatch-logs"
  policy      = templatefile("${path.root}/policies/cloudwatch-logs-rw.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_rds_utility_task_execution_cloudwatch_logs" {
  for_each = local.infrastructure_rds

  role       = aws_iam_role.infrastructure_rds_utility_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_utility_task_execution_cloudwatch_logs[each.key].arn
}

resource "aws_iam_policy" "infrastructure_rds_utility_task_execution_get_secret_value" {
  for_each = local.infrastructure_rds

  name        = "${local.resource_prefix}-${substr(sha512("rds-utility-task-execution-${each.key}-get-secret-value"), 0, 6)}"
  description = "${local.resource_prefix}-rds-utility-task-execution-${each.key}-get-secret-value"
  policy = templatefile("${path.root}/policies/secrets-manager-get-secret-value.json.tpl", {
    secret_name_arns = jsonencode([
      aws_secretsmanager_secret.infrastructure_rds_root_password[each.key].arn,
    ])
  })
}

resource "aws_iam_role_policy_attachment" "infrastructure_rds_utility_task_execution_get_secret_value" {
  for_each = local.infrastructure_rds

  role       = aws_iam_role.infrastructure_rds_utility_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_utility_task_execution_get_secret_value[each.key].arn
}

resource "aws_iam_role" "infrastructure_rds_utility_task" {
  for_each = local.infrastructure_rds

  name        = "${local.resource_prefix}-${substr(sha512("rds-utility-task-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-rds-utility-task-${each.key}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_rds_utility_task_ssm_create_channels" {
  for_each = local.infrastructure_rds

  name        = "${local.resource_prefix}-${substr(sha512("rds-utility-task-${each.key}-create-channels"), 0, 6)}"
  description = "${local.resource_prefix}-rds-utility-task-${each.key}-create-channels"
  policy      = templatefile("${path.root}/policies/ssm-create-channels.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_rds_utility_task_ssm_create_channels" {
  for_each = local.infrastructure_rds

  role       = aws_iam_role.infrastructure_rds_utility_task[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_utility_task_ssm_create_channels[each.key].arn
}

resource "aws_iam_policy" "infrastructure_rds_utility_task_kms_encrypt" {
  for_each = local.infrastructure_kms_encryption ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("-rds-utility-task-${each.key}-kms-encrypt"), 0, 6)}"
  description = "${local.resource_prefix}--rds-utility-task-${each.key}-kms-encrypt"
  policy = templatefile(
    "${path.root}/policies/kms-encrypt.json.tpl",
    { kms_key_arn = aws_kms_key.infrastructure[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_rds_utility_task_kms_encrypt" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  role       = aws_iam_role.infrastructure_rds_utility_task[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_utility_task_kms_encrypt[each.key].arn
}

resource "aws_ecs_task_definition" "infrastructure_rds_utility_scheduled_task" {
  for_each = local.infrastructure_rds

  family = "${local.resource_prefix}-rds-utility-${each.key}"
  container_definitions = templatefile(
    "./container-definitions/app.json.tpl",
    {
      container_name      = "rds-utility-${each.key}"
      image               = aws_ecr_repository.infrastructure_rds_s3_backups[0].repository_url
      entrypoint          = jsonencode(["/bin/bash", "-c", "sleep 3600"])
      command             = jsonencode([])
      environment_file_s3 = ""
      environment = jsonencode([
        {
          name  = "DB_HOST",
          value = each.value["type"] == "instance" ? aws_db_instance.infrastructure_rds[each.key].address : each.value["type"] == "cluster" ? aws_rds_cluster.infrastructure_rds[each.key].reader_endpoint : null
        },
        {
          name  = "DB_USER",
          value = "root"
        },
        {
          name  = "DB_PORT",
          value = tostring(local.rds_ports[each.value["engine"]])
        }
      ])
      secrets = jsonencode([
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_secretsmanager_secret.infrastructure_rds_root_password[each.key].arn,
        }
      ])
      container_port = 0
      extra_hosts    = jsonencode([])
      volumes        = jsonencode([])
      linux_parameters = jsonencode({
        initProcessEnabled = true
      })
      syslog_address        = ""
      syslog_tag            = ""
      cloudwatch_log_group  = aws_cloudwatch_log_group.infrastructure_rds_s3_backups[each.key].name
      awslogs_stream_prefix = "${local.resource_prefix}-rds-util-${each.key}"
      region                = local.aws_region
    }
  )
  execution_role_arn       = aws_iam_role.infrastructure_rds_utility_task_execution[each.key].arn
  task_role_arn            = aws_iam_role.infrastructure_rds_utility_task[each.key].arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = 1024
  cpu                      = 512

  depends_on = [
    aws_iam_role_policy_attachment.infrastructure_rds_utility_task_execution_ecr_pull,
    aws_iam_role_policy_attachment.infrastructure_rds_utility_task_execution_cloudwatch_logs,
    terraform_data.infrastructure_rds_s3_backups_image_build_trigger_codebuild,
  ]
}
