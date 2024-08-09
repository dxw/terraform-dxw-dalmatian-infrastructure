resource "aws_iam_role" "infrastructure_rds_s3_backups_task_execution" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("rds-s3-backups-task-execution-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-rds-s3-backups-task-execution-${each.key}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_rds_s3_backups_task_execution_ecr_pull" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("rds-s3-backups-task-execution-${each.key}-ecr-pull"), 0, 6)}"
  description = "${local.resource_prefix}-rds-s3-backups-task-execution-${each.key}-ecr-pull"
  policy = templatefile(
    "${path.root}/policies/ecr-pull.json.tpl",
    { ecr_repository_arn = aws_ecr_repository.infrastructure_rds_s3_backups[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_rds_s3_backups_task_execution_ecr_pull" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  role       = aws_iam_role.infrastructure_rds_s3_backups_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_s3_backups_task_execution_ecr_pull[each.key].arn
}

resource "aws_iam_policy" "infrastructure_rds_s3_backups_task_execution_cloudwatch_logs" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("rds-s3-backups-task-execution-${each.key}-cloudwatch-logs"), 0, 6)}"
  description = "${local.resource_prefix}-rds-s3-backups-task-execution-${each.key}-cloudwatch-logs"
  policy      = templatefile("${path.root}/policies/cloudwatch-logs-rw.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_rds_s3_backups_task_execution_cloudwatch_logs" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  role       = aws_iam_role.infrastructure_rds_s3_backups_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_s3_backups_task_execution_cloudwatch_logs[each.key].arn
}

resource "aws_iam_policy" "infrastructure_rds_s3_backups_task_execution_get_secret_value" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("rds-s3-backups-task-execution-${each.key}-get-secret-value"), 0, 6)}"
  description = "${local.resource_prefix}-rds-s3-backups-task-execution-${each.key}-get-secret-value"
  policy = templatefile("${path.root}/policies/secrets-manager-get-secret-value.json.tpl", {
    secret_name_arns = jsonencode([
      aws_secretsmanager_secret.infrastructure_rds_root_password[each.key].arn,
    ])
  })
}

resource "aws_iam_role_policy_attachment" "infrastructure_rds_s3_backups_task_execution_get_secret_value" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  role       = aws_iam_role.infrastructure_rds_s3_backups_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_s3_backups_task_execution_get_secret_value[each.key].arn
}

resource "aws_iam_role" "infrastructure_rds_s3_backups_task" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("rds-s3-backups-task-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-rds-s3-backups-task-${each.key}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_rds_s3_backups_task_s3_write" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("rds-s3-backups-task-${each.key}-s3-write"), 0, 6)}"
  description = "${local.resource_prefix}-rds-s3-backups-task-${each.key}-s3-write"
  policy = templatefile("${path.root}/policies/s3-object-write.json.tpl", {
    bucket_arn = aws_s3_bucket.infrastructure_rds_s3_backups[0].arn
    path       = each.value["type"] == "instance" ? "/${aws_db_instance.infrastructure_rds[each.key].address}/*" : each.value["type"] == "cluster" ? "/${aws_rds_cluster.infrastructure_rds[each.key].reader_endpoint}/*" : null
  })
}

resource "aws_iam_role_policy_attachment" "infrastructure_rds_s3_backups_task_s3_write" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  role       = aws_iam_role.infrastructure_rds_s3_backups_task[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_s3_backups_task_s3_write[each.key].arn
}

resource "aws_iam_policy" "infrastructure_rds_s3_backups_task_s3_list" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("rds-s3-backups-task-${each.key}-s3-list"), 0, 6)}"
  description = "${local.resource_prefix}-rds-s3-backups-task-${each.key}-s3-list"
  policy = templatefile("${path.root}/policies/s3-list.json.tpl", {
    bucket_arn = aws_s3_bucket.infrastructure_rds_s3_backups[0].arn
  })
}

resource "aws_iam_role_policy_attachment" "infrastructure_rds_s3_backups_task_s3_list" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  role       = aws_iam_role.infrastructure_rds_s3_backups_task[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_s3_backups_task_s3_list[each.key].arn
}

resource "aws_iam_policy" "infrastructure_rds_s3_backups_task_kms_encrypt" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 && local.infrastructure_kms_encryption ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("rds-s3-backups-task-${each.key}-kms-encrypt"), 0, 6)}"
  description = "${local.resource_prefix}-rds-s3-backups-task-${each.key}-kms-encrypt"
  policy = templatefile(
    "${path.root}/policies/kms-encrypt.json.tpl",
    { kms_key_arn = aws_kms_key.infrastructure[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_rds_s3_backups_task_kms_encrypt" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  role       = aws_iam_role.infrastructure_rds_s3_backups_task[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_s3_backups_task_kms_encrypt[each.key].arn
}

resource "aws_ecs_task_definition" "infrastructure_rds_s3_backups_scheduled_task" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  family = "${local.resource_prefix}-rds-s3-backups-${each.key}"
  container_definitions = templatefile(
    "./container-definitions/app.json.tpl",
    {
      container_name = "rds-s3-backups-${each.key}"
      image          = aws_ecr_repository.infrastructure_rds_s3_backups[0].repository_url
      entrypoint = jsonencode(["/bin/bash", "-c", templatefile(
        local.rds_s3_backups_container_entrypoint_file[each.value["engine"]],
        {
          s3_bucket_name = aws_s3_bucket.infrastructure_rds_s3_backups[0].bucket
        }
      )])
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
        initProcessEnabled = false
      })
      cloudwatch_log_group  = aws_cloudwatch_log_group.infrastructure_rds_s3_backups[each.key].name
      awslogs_stream_prefix = "${local.resource_prefix}-rds-s3-backups-${each.key}"
      region                = local.aws_region
    }
  )
  execution_role_arn       = aws_iam_role.infrastructure_rds_s3_backups_task_execution[each.key].arn
  task_role_arn            = aws_iam_role.infrastructure_rds_s3_backups_task[each.key].arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = 1024
  cpu                      = 512

  depends_on = [
    aws_iam_role_policy_attachment.infrastructure_rds_s3_backups_task_execution_ecr_pull,
    aws_iam_role_policy_attachment.infrastructure_rds_s3_backups_task_execution_cloudwatch_logs,
    aws_iam_role_policy_attachment.infrastructure_rds_s3_backups_task_s3_write,
    aws_iam_role_policy_attachment.infrastructure_rds_s3_backups_task_kms_encrypt,
    terraform_data.infrastructure_rds_s3_backups_image_build_trigger_codebuild,
  ]
}
