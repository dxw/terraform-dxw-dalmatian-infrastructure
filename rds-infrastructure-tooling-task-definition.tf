resource "aws_ecs_task_definition" "infrastructure_rds_tooling" {
  for_each = local.enable_infrastructure_rds_tooling ? merge(local.infrastructure_rds, length(local.infrastructure_s3_to_azure_backup) > 0 ? { s3toazurebackup = {} } : {}) : {}

  family = "${local.resource_prefix}-infrastructure-rds-tooling-${each.key}"
  container_definitions = templatefile(
    "./container-definitions/app.json.tpl",
    {
      container_name      = "rds-tooling-${each.key}"
      image               = aws_ecr_repository.infrastructure_rds_tooling[0].repository_url
      entrypoint          = jsonencode([])
      command             = jsonencode([])
      environment_file_s3 = ""
      environment = jsonencode(
        concat(each.key != "s3toazurebackup" ? [
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
          },
          ] : [],
          each.key != "s3toazurebackup" ? strcontains(local.rds_engines[each.value["type"]][each.value["engine"]], "postgres") ? [
            {
              name  = "DEFAULT_DB_NAME"
              value = "postgres"
            },
          ] : [] : [],
          local.infrastructure_s3_to_azure_backup_azure_tenant_id != "" ? [
            {
              name  = "AZCOPY_TENANT_ID"
              value = local.infrastructure_s3_to_azure_backup_azure_tenant_id
            },
          ] : [],
          local.infrastructure_s3_to_azure_backup_azure_spa_application_id != "" ? [
            {
              name  = "AZCOPY_SPA_APPLICATION_ID"
              value = local.infrastructure_s3_to_azure_backup_azure_spa_application_id
            },
            {
              name  = "AZCOPY_AUTO_LOGIN_TYPE"
              value = "SPN"
            },
          ] : [],
          local.infrastructure_s3_to_azure_backup_azure_spa_client_secret != "" ? [
            {
              name  = "AZCOPY_SPA_CLIENT_SECRET"
              value = local.infrastructure_s3_to_azure_backup_azure_spa_client_secret
            },
          ] : [],
        )
      )
      secrets = jsonencode([
        {
          name      = "DB_PASSWORD"
          valueFrom = each.value["type"] == "instance" ? aws_db_instance.infrastructure_rds[each.key].master_user_secret.secret_arn : each.value["type"] == "cluster" ? "${aws_rds_cluster.infrastructure_rds[each.key].master_user_secret[0].secret_arn}:password::" : null
        }
      ])
      container_port = 0
      extra_hosts    = jsonencode([])
      volumes        = jsonencode([])
      linux_parameters = jsonencode({
        initProcessEnabled = false
      })
      security_options      = jsonencode([])
      syslog_address        = ""
      syslog_tag            = ""
      cloudwatch_log_group  = aws_cloudwatch_log_group.infrastructure_rds_tooling[each.key].name
      awslogs_stream_prefix = "rds-tooling"
      region                = local.aws_region
    }
  )
  execution_role_arn       = aws_iam_role.infrastructure_rds_tooling_task_execution[each.key].arn
  task_role_arn            = aws_iam_role.infrastructure_rds_tooling_task[each.key].arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = 1024
  cpu                      = 512

  depends_on = [
    aws_iam_role_policy_attachment.infrastructure_rds_tooling_task_execution_ecr_pull,
    aws_iam_role_policy_attachment.infrastructure_rds_tooling_task_execution_cloudwatch_logs,
    aws_iam_role_policy_attachment.infrastructure_rds_s3_backups_task_s3_write,
    aws_iam_role_policy_attachment.infrastructure_rds_tooling_task_kms_encrypt,
    terraform_data.infrastructure_rds_tooling_image_build_trigger_codebuild,
  ]
}
