resource "aws_iam_role" "infrastructure_utilities_task_execution" {
  for_each = local.enable_infrastructure_utilities ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("utilities-task-execution-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-utilities-task-execution-${each.key}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_utilities_task_execution_ecr_pull" {
  for_each = local.enable_infrastructure_utilities ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("utilities-task-execution-${each.key}-ecr-pull"), 0, 6)}"
  description = "${local.resource_prefix}-utilities-task-execution-${each.key}-ecr-pull"
  policy = templatefile(
    "${path.root}/policies/ecr-pull.json.tpl",
    { ecr_repository_arn = aws_ecr_repository.infrastructure_utilities[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_utilities_task_execution_ecr_pull" {
  for_each = local.enable_infrastructure_utilities ? local.infrastructure_rds : {}

  role       = aws_iam_role.infrastructure_utilities_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_utilities_task_execution_ecr_pull[each.key].arn
}

resource "aws_iam_policy" "infrastructure_utilities_task_execution_cloudwatch_logs" {
  for_each = local.enable_infrastructure_utilities ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("utilities-task-execution-${each.key}-cloudwatch-logs"), 0, 6)}"
  description = "${local.resource_prefix}-utilities-task-execution-${each.key}-cloudwatch-logs"
  policy      = templatefile("${path.root}/policies/cloudwatch-logs-rw.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_utilities_task_execution_cloudwatch_logs" {
  for_each = local.enable_infrastructure_utilities ? local.infrastructure_rds : {}

  role       = aws_iam_role.infrastructure_utilities_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_utilities_task_execution_cloudwatch_logs[each.key].arn
}

resource "aws_iam_policy" "infrastructure_utilities_task_execution_get_secret_value" {
  for_each = local.enable_infrastructure_utilities ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("utilities-task-execution-${each.key}-get-secret-value"), 0, 6)}"
  description = "${local.resource_prefix}-utilities-task-execution-${each.key}-get-secret-value"
  policy = templatefile("${path.root}/policies/secrets-manager-get-secret-value.json.tpl", {
    secret_name_arns = jsonencode([
      each.value["type"] == "instance" ? aws_db_instance.infrastructure_rds[each.key].master_user_secret.secret_arn : each.value["type"] == "cluster" ? aws_rds_cluster.infrastructure_rds[each.key].master_user_secret[0].secret_arn : null,
    ])
  })
}

resource "aws_iam_role_policy_attachment" "infrastructure_utilities_task_execution_get_secret_value" {
  for_each = local.enable_infrastructure_utilities ? local.infrastructure_rds : {}

  role       = aws_iam_role.infrastructure_utilities_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_utilities_task_execution_get_secret_value[each.key].arn
}

resource "aws_iam_policy" "infrastructure_utilities_task_execution_ecs_get_secret_value_kms_decrypt" {
  for_each = local.enable_infrastructure_utilities ? {
    for k, v in local.infrastructure_rds : k => v if local.infrastructure_kms_encryption || v["dedicated_kms_key"] == true
  } : {}

  name        = "${local.resource_prefix}-${substr(sha512("utilities-task-${each.key}-get-secret-value-kms-decrypt"), 0, 6)}"
  description = "${local.resource_prefix}-utilities-task-${each.key}-get-secret-value-kms-decrypt"
  policy = templatefile("${path.root}/policies/kms-decrypt.json.tpl", {
    kms_key_arn = each.value["dedicated_kms_key"] == true ? aws_kms_key.infrastructure_rds[each.key].arn : aws_kms_key.infrastructure[0].arn
  })
}

resource "aws_iam_role_policy_attachment" "infrastructure_utilities_task_execution_ecs_get_secret_value_kms_decrypt" {
  for_each = local.enable_infrastructure_utilities ? {
    for k, v in local.infrastructure_rds : k => v if local.infrastructure_kms_encryption || v["dedicated_kms_key"] == true
  } : {}

  role       = aws_iam_role.infrastructure_utilities_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_utilities_task_execution_ecs_get_secret_value_kms_decrypt[each.key].arn
}

resource "aws_iam_role" "infrastructure_utilities_task" {
  for_each = local.enable_infrastructure_utilities ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("utilities-task-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-utilities-task-${each.key}"
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

  role       = aws_iam_role.infrastructure_utilities_task[each.key].name
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

  role       = aws_iam_role.infrastructure_utilities_task[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_s3_backups_task_s3_list[each.key].arn
}

resource "aws_iam_policy" "infrastructure_utilities_task_ssm_create_channels" {
  for_each = local.enable_infrastructure_utilities ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("utilities-task-${each.key}-ssm-create-channels"), 0, 6)}"
  description = "${local.resource_prefix}-utilities-task-${each.key}-ssm-create-channels"
  policy      = templatefile("${path.root}/policies/ssm-create-channels.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_utilities_task_ssm_create_channels" {
  for_each = local.enable_infrastructure_utilities ? local.infrastructure_rds : {}

  role       = aws_iam_role.infrastructure_utilities_task[each.key].name
  policy_arn = aws_iam_policy.infrastructure_utilities_task_ssm_create_channels[each.key].arn
}

resource "aws_iam_policy" "infrastructure_utilities_task_ecs_exec_log_s3_write" {
  for_each = local.enable_infrastructure_utilities ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("utilities-task-${each.key}-ecs-exec-log-s3-write"), 0, 6)}"
  description = "${local.resource_prefix}-utilities-task-${each.key}-ecs-exec-log-s3-write"
  policy = templatefile("${path.root}/policies/s3-object-write.json.tpl", {
    bucket_arn = aws_s3_bucket.infrastructure_logs[0].arn
    path       = "/ecs-exec/*"
  })
}

resource "aws_iam_role_policy_attachment" "infrastructure_utilities_task_ecs_exec_log_s3_write" {
  for_each = local.enable_infrastructure_utilities ? local.infrastructure_rds : {}

  role       = aws_iam_role.infrastructure_utilities_task[each.key].name
  policy_arn = aws_iam_policy.infrastructure_utilities_task_ecs_exec_log_s3_write[each.key].arn
}

resource "aws_iam_policy" "infrastructure_utilities_task_ecs_exec_log_kms_decrypt" {
  for_each = local.enable_infrastructure_utilities ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("utilities-task-${each.key}-ecs-exec-log-kms-decrypt"), 0, 6)}"
  description = "${local.resource_prefix}-utilities-task-${each.key}-ecs-exec-log-kms-decrypt"
  policy = templatefile("${path.root}/policies/kms-decrypt.json.tpl", {
    kms_key_arn = aws_kms_key.infrastructure[0].arn
  })
}

resource "aws_iam_role_policy_attachment" "infrastructure_utilities_task_ecs_exec_log_kms_decrypt" {
  for_each = local.enable_infrastructure_utilities ? local.infrastructure_rds : {}

  role       = aws_iam_role.infrastructure_utilities_task[each.key].name
  policy_arn = aws_iam_policy.infrastructure_utilities_task_ecs_exec_log_kms_decrypt[each.key].arn
}

resource "aws_iam_policy" "infrastructure_utilities_task_kms_encrypt" {
  for_each = local.enable_infrastructure_utilities && local.infrastructure_kms_encryption ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${substr(sha512("utilities-task-${each.key}-kms-encrypt"), 0, 6)}"
  description = "${local.resource_prefix}-utilities-task-${each.key}-kms-encrypt"
  policy = templatefile(
    "${path.root}/policies/kms-encrypt.json.tpl",
    { kms_key_arn = aws_kms_key.infrastructure[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_utilities_task_kms_encrypt" {
  for_each = local.enable_infrastructure_utilities ? local.infrastructure_rds : {}

  role       = aws_iam_role.infrastructure_utilities_task[each.key].name
  policy_arn = aws_iam_policy.infrastructure_utilities_task_kms_encrypt[each.key].arn
}
