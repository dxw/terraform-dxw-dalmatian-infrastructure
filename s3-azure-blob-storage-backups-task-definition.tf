resource "aws_iam_role" "s3_azure_blob_storage_backups_task_execution" {
  for_each = local.enable_s3_backup_to_azure_blob_storage ? local.s3_backup_to_azure_blob_storage_source_and_targets : {}

  name        = "${local.resource_prefix}-${substr(sha512("s3-azure-blob-storage-backups-task-execution-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-s3-azure-blob-storage-backups-task-execution-${each.key}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "s3_azure_blob_storage_backups_task_execution_ecr_pull" {
  for_each = local.enable_s3_backup_to_azure_blob_storage ? local.s3_backup_to_azure_blob_storage_source_and_targets : {}

  name        = "${local.resource_prefix}-${substr(sha512("s3-azure-blob-storage-backups-task-execution-${each.key}-ecr-pull"), 0, 6)}"
  description = "${local.resource_prefix}-s3-azure-blob-storage-backups-task-execution-${each.key}-ecr-pull"
  policy = templatefile(
    "${path.root}/policies/ecr-pull.json.tpl",
    { ecr_repository_arn = aws_ecr_repository.s3_azure_blob_storage_backups[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "s3_azure_blob_storage_backups_task_execution_ecr_pull" {
  for_each = local.enable_s3_backup_to_azure_blob_storage ? local.s3_backup_to_azure_blob_storage_source_and_targets : {}

  role       = aws_iam_role.s3_azure_blob_storage_backups_task_execution[each.key].name
  policy_arn = aws_iam_policy.s3_azure_blob_storage_backups_task_execution_ecr_pull[each.key].arn
}

resource "aws_iam_policy" "s3_azure_blob_storage_backups_task_execution_cloudwatch_logs" {
  for_each = local.enable_s3_backup_to_azure_blob_storage ? local.s3_backup_to_azure_blob_storage_source_and_targets : {}

  name        = "${local.resource_prefix}-${substr(sha512("s3-azure-blob-storage-backups-task-execution-${each.key}-cloudwatch-logs"), 0, 6)}"
  description = "${local.resource_prefix}-s3-azure-blob-storage-backups-task-execution-${each.key}-cloudwatch-logs"
  policy      = templatefile("${path.root}/policies/cloudwatch-logs-rw.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "s3_azure_blob_storage_backups_task_execution_cloudwatch_logs" {
  for_each = local.enable_s3_backup_to_azure_blob_storage ? local.s3_backup_to_azure_blob_storage_source_and_targets : {}

  role       = aws_iam_role.s3_azure_blob_storage_backups_task_execution[each.key].name
  policy_arn = aws_iam_policy.s3_azure_blob_storage_backups_task_execution_cloudwatch_logs[each.key].arn
}

resource "aws_iam_role" "s3_azure_blob_storage_backups_task" {
  for_each = local.enable_s3_backup_to_azure_blob_storage ? local.s3_backup_to_azure_blob_storage_source_and_targets : {}

  name        = "${local.resource_prefix}-${substr(sha512("s3-azure-blob-storage-backups-task-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-s3-azure-blob-storage-backups-task-${each.key}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "s3_azure_blob_storage_backups_task_s3_read" {
  for_each = local.enable_s3_backup_to_azure_blob_storage ? local.s3_backup_to_azure_blob_storage_source_and_targets : {}

  name        = "${local.resource_prefix}-${substr(sha512("s3-azure-blob-storage-backups-task-${each.key}-s3-read"), 0, 6)}"
  description = "${local.resource_prefix}-s3-azure-blob-storage-backups-task-${each.key}-s3-read"
  policy = templatefile("${path.root}/policies/s3-object-read.json.tpl", {
    bucket_arn = "arn:aws:s3:::${each.key}"
  })
}

resource "aws_iam_role_policy_attachment" "s3_azure_blob_storage_backups_task_s3_read" {
  for_each = local.enable_s3_backup_to_azure_blob_storage ? local.s3_backup_to_azure_blob_storage_source_and_targets : {}

  role       = aws_iam_role.s3_azure_blob_storage_backups_task[each.key].name
  policy_arn = aws_iam_policy.s3_azure_blob_storage_backups_task_s3_read[each.key].arn
}

resource "aws_iam_policy" "s3_azure_blob_storage_backups_task_kms_decrypt" {
  for_each = local.enable_s3_backup_to_azure_blob_storage ? local.s3_backup_to_azure_blob_storage_source_and_targets : {}

  name        = "${local.resource_prefix}-${substr(sha512("s3-azure-blob-storage-backups-task-${each.key}-kms-decrypt"), 0, 6)}"
  description = "${local.resource_prefix}-s3-azure-blob-storage-backups-task-${each.key}-kms-decrypt"
  policy = templatefile(
    "${path.root}/policies/kms-decrypt.json.tpl",
    { kms_key_arn = each.value["s3_bucket_kms_key_arn"] }
  )
}

resource "aws_iam_role_policy_attachment" "s3_azure_blob_storage_backups_task_kms_decrypt" {
  for_each = local.enable_s3_backup_to_azure_blob_storage ? local.s3_backup_to_azure_blob_storage_source_and_targets : {}

  role       = aws_iam_role.s3_azure_blob_storage_backups_task[each.key].name
  policy_arn = aws_iam_policy.s3_azure_blob_storage_backups_task_kms_decrypt[each.key].arn
}

resource "aws_ecs_task_definition" "s3_azure_blob_storage_backups_scheduled_task" {
  for_each = local.enable_s3_backup_to_azure_blob_storage ? local.s3_backup_to_azure_blob_storage_source_and_targets : {}

  family = "${local.resource_prefix}-s3-azure-blob-storage-backups-${each.key}"
  container_definitions = templatefile(
    "./container-definitions/app.json.tpl",
    {
      container_name      = "s3-azure-blob-storage-backups-${each.key}"
      image               = aws_ecr_repository.s3_azure_blob_storage_backups[0].repository_url
      entrypoint          = jsonencode(["/bin/bash", "-c", "/entrypoint"])
      command             = jsonencode([])
      environment_file_s3 = ""
      environment = jsonencode([
        {
          name  = "AZCOPY_AUTO_LOGIN_TYPE",
          value = local.s3_backup_to_azure_blob_storage_login_type
        },
        {
          name  = "AZCOPY_SPA_APPLICATION_ID",
          value = local.s3_backup_to_azure_blob_storage_spa_application_id
        },
        {
          name  = "AZCOPY_SPA_CLIENT_SECRET",
          value = local.s3_backup_to_azure_blob_storage_spa_client_secret
        },
        {
          name  = "AZCOPY_TENANT_ID"
          value = local.s3_backup_to_azure_blob_storage_tenant_id
        },
        {
          name  = "SOURCE"
          value = "https://${each.key}.s3.${local.aws_region}.amazonaws.com"
        },
        {
          name  = "DESTINATION"
          value = "https://${each.value["blob_storage_account_name"]}.blob.core.windows.net/${each.value["blob_storage_container_name"]}"
        }
      ])
      secrets        = jsonencode([])
      container_port = 0
      extra_hosts    = jsonencode([])
      volumes        = jsonencode([])
      linux_parameters = jsonencode({
        initProcessEnabled = false
      })
      security_options      = jsonencode([])
      syslog_address        = ""
      syslog_tag            = ""
      cloudwatch_log_group  = aws_cloudwatch_log_group.s3_azure_blob_storage_backups[each.key].name
      awslogs_stream_prefix = "${local.resource_prefix}-s3-azure-blob-storage-backups-${each.key}"
      region                = local.aws_region
    }
  )
  execution_role_arn       = aws_iam_role.s3_azure_blob_storage_backups_task_execution[each.key].arn
  task_role_arn            = aws_iam_role.s3_azure_blob_storage_backups_task[each.key].arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = 1024
  cpu                      = 512

  depends_on = [
    aws_iam_role_policy_attachment.s3_azure_blob_storage_backups_task_execution_ecr_pull,
    aws_iam_role_policy_attachment.s3_azure_blob_storage_backups_task_execution_cloudwatch_logs,
    aws_iam_role_policy_attachment.s3_azure_blob_storage_backups_task_s3_read,
    aws_iam_role_policy_attachment.s3_azure_blob_storage_backups_task_kms_decrypt,
    terraform_data.s3_azure_blob_storage_backups_image_build_trigger_codebuild,
  ]
}
