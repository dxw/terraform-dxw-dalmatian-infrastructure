resource "aws_iam_role" "infrastructure_s3_to_azure_task" {
  count = local.enable_s3_to_azure_scheduled_tasks ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("s3-to-azure-task"), 0, 6)}"
  description = "${local.resource_prefix}-s3-to-azure-task"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_s3_to_azure_task_s3_read" {
  for_each = local.enable_s3_to_azure_scheduled_tasks ? local.s3_to_azure_sync_jobs : {}

  name        = "${local.resource_prefix}-${substr(sha512("s3-to-azure-task-s3-read-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-s3-to-azure-task-s3-read-${each.key}"
  policy = templatefile(
    "${path.root}/policies/s3-object-read.json.tpl",
    {
      bucket_arn = each.value.source_bucket_arn
    }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_s3_to_azure_task_s3_read" {
  for_each = local.enable_s3_to_azure_scheduled_tasks ? local.s3_to_azure_sync_jobs : {}

  role       = aws_iam_role.infrastructure_s3_to_azure_task[0].name
  policy_arn = aws_iam_policy.infrastructure_s3_to_azure_task_s3_read[each.key].arn
}

# Source objects are SSE-KMS encrypted and the key policies delegate to IAM, so
# GetObject also needs kms:Decrypt. Without it S3 returns 403 and azcopy's
# server-to-server copy fails with CannotVerifyCopySource. The key differs per
# source bucket, hence one policy per job rather than one for the whole role.
resource "aws_iam_policy" "infrastructure_s3_to_azure_task_kms_decrypt" {
  for_each = local.enable_s3_to_azure_scheduled_tasks ? {
    for k, v in local.s3_to_azure_sync_jobs : k => v
    if local.s3_to_azure_sync_job_source_kms_key_arns[k] != null
  } : {}

  name        = "${local.resource_prefix}-${substr(sha512("s3-to-azure-task-kms-decrypt-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-s3-to-azure-task-kms-decrypt-${each.key}"
  policy = templatefile(
    "${path.root}/policies/kms-decrypt.json.tpl",
    { kms_key_arn = local.s3_to_azure_sync_job_source_kms_key_arns[each.key] }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_s3_to_azure_task_kms_decrypt" {
  for_each = local.enable_s3_to_azure_scheduled_tasks ? {
    for k, v in local.s3_to_azure_sync_jobs : k => v
    if local.s3_to_azure_sync_job_source_kms_key_arns[k] != null
  } : {}

  role       = aws_iam_role.infrastructure_s3_to_azure_task[0].name
  policy_arn = aws_iam_policy.infrastructure_s3_to_azure_task_kms_decrypt[each.key].arn
}

resource "aws_iam_role" "infrastructure_s3_to_azure_task_execution" {
  count = local.enable_s3_to_azure_scheduled_tasks ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("s3-to-azure-task-execution"), 0, 6)}"
  description = "${local.resource_prefix}-s3-to-azure-task-execution"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_s3_to_azure_task_execution_ssm" {
  count = local.enable_s3_to_azure_scheduled_tasks ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("s3-to-azure-task-execution-ssm"), 0, 6)}"
  description = "${local.resource_prefix}-s3-to-azure-task-execution-ssm"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Effect = "Allow"
        Resource = [
          local.s3_to_azure_ssm_arn_tenant_id,
          local.s3_to_azure_ssm_arn_application_id,
          local.s3_to_azure_ssm_arn_client_secret
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "infrastructure_s3_to_azure_task_execution_ssm" {
  count = local.enable_s3_to_azure_scheduled_tasks ? 1 : 0

  role       = aws_iam_role.infrastructure_s3_to_azure_task_execution[0].name
  policy_arn = aws_iam_policy.infrastructure_s3_to_azure_task_execution_ssm[0].arn
}

resource "aws_iam_policy" "infrastructure_s3_to_azure_task_execution_kms_decrypt" {
  count = local.enable_s3_to_azure_scheduled_tasks && local.infrastructure_kms_encryption ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("s3-to-azure-task-execution-kms-decrypt"), 0, 6)}"
  description = "${local.resource_prefix}-s3-to-azure-task-execution-kms-decrypt"
  policy = templatefile(
    "${path.root}/policies/kms-decrypt.json.tpl",
    { kms_key_arn = aws_kms_key.infrastructure[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_s3_to_azure_task_execution_kms_decrypt" {
  count = local.enable_s3_to_azure_scheduled_tasks && local.infrastructure_kms_encryption ? 1 : 0

  role       = aws_iam_role.infrastructure_s3_to_azure_task_execution[0].name
  policy_arn = aws_iam_policy.infrastructure_s3_to_azure_task_execution_kms_decrypt[0].arn
}

resource "aws_iam_policy" "infrastructure_s3_to_azure_task_execution_cloudwatch_logs" {
  count = local.enable_s3_to_azure_scheduled_tasks ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("s3-to-azure-task-execution-cloudwatch"), 0, 6)}"
  description = "${local.resource_prefix}-s3-to-azure-task-execution-cloudwatch"
  policy      = templatefile("${path.root}/policies/cloudwatch-logs-rw.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_s3_to_azure_task_execution_cloudwatch_logs" {
  count = local.enable_s3_to_azure_scheduled_tasks ? 1 : 0

  role       = aws_iam_role.infrastructure_s3_to_azure_task_execution[0].name
  policy_arn = aws_iam_policy.infrastructure_s3_to_azure_task_execution_cloudwatch_logs[0].arn
}

resource "aws_cloudwatch_log_group" "infrastructure_s3_to_azure" {
  count = local.enable_s3_to_azure_scheduled_tasks ? 1 : 0

  name              = "/ecs/${local.resource_prefix}-s3-to-azure"
  retention_in_days = 30
  kms_key_id        = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  skip_destroy      = true
}

resource "aws_ecs_task_definition" "infrastructure_s3_to_azure" {
  count = local.enable_s3_to_azure_scheduled_tasks ? 1 : 0

  family = "${local.resource_prefix}-s3-to-azure"
  container_definitions = templatefile(
    "./container-definitions/app.json.tpl",
    {
      container_name      = "s3-to-azure"
      image               = "thedxw/dalmatian-s3-azure-docker:latest"
      entrypoint          = jsonencode([])
      command             = jsonencode([])
      environment_file_s3 = ""
      environment = jsonencode([
        {
          name  = "AZCOPY_AUTO_LOGIN_TYPE",
          value = "SPN"
        }
      ])
      secrets = jsonencode([
        {
          name      = "AZCOPY_TENANT_ID"
          valueFrom = local.s3_to_azure_ssm_arn_tenant_id
        },
        {
          name      = "AZCOPY_SPA_APPLICATION_ID"
          valueFrom = local.s3_to_azure_ssm_arn_application_id
        },
        {
          name      = "AZCOPY_SPA_CLIENT_SECRET"
          valueFrom = local.s3_to_azure_ssm_arn_client_secret
        }
      ])
      container_port        = 0
      extra_hosts           = jsonencode([])
      volumes               = jsonencode([])
      linux_parameters      = jsonencode({ initProcessEnabled = false })
      security_options      = jsonencode([])
      syslog_address        = ""
      syslog_tag            = ""
      cloudwatch_log_group  = aws_cloudwatch_log_group.infrastructure_s3_to_azure[0].name
      awslogs_stream_prefix = "s3-to-azure"
      region                = local.aws_region
    }
  )
  execution_role_arn       = aws_iam_role.infrastructure_s3_to_azure_task_execution[0].arn
  task_role_arn            = aws_iam_role.infrastructure_s3_to_azure_task[0].arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = 1024
  cpu                      = 512
}

resource "aws_iam_role" "infrastructure_s3_to_azure_cloudwatch_schedule" {
  count = local.enable_s3_to_azure_scheduled_tasks ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("s3-to-azure-cloudwatch-schedule"), 0, 6)}"
  description = "${local.resource_prefix}-s3-to-azure-cloudwatch-schedule"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["events.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_s3_to_azure_cloudwatch_schedule_ecs_run_task" {
  count = local.enable_s3_to_azure_scheduled_tasks ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("s3-to-azure-cloudwatch-schedule-ecs-run-task"), 0, 6)}"
  description = "${local.resource_prefix}-s3-to-azure-cloudwatch-schedule-ecs-run-task"
  policy      = templatefile("${path.root}/policies/ecs-run-task.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_s3_to_azure_cloudwatch_schedule_ecs_run_task" {
  count = local.enable_s3_to_azure_scheduled_tasks ? 1 : 0

  role       = aws_iam_role.infrastructure_s3_to_azure_cloudwatch_schedule[0].name
  policy_arn = aws_iam_policy.infrastructure_s3_to_azure_cloudwatch_schedule_ecs_run_task[0].arn
}

resource "aws_iam_policy" "infrastructure_s3_to_azure_cloudwatch_schedule_pass_role" {
  count = local.enable_s3_to_azure_scheduled_tasks ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("s3-to-azure-cloudwatch-schedule-pass-role"), 0, 6)}"
  description = "${local.resource_prefix}-s3-to-azure-cloudwatch-schedule-pass-role"
  policy = templatefile(
    "${path.root}/policies/pass-role.json.tpl",
    {
      role_arns = jsonencode([
        aws_iam_role.infrastructure_s3_to_azure_task_execution[0].arn,
        aws_iam_role.infrastructure_s3_to_azure_task[0].arn,
      ])
      services = jsonencode(["ecs-tasks.amazonaws.com"])
    }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_s3_to_azure_cloudwatch_schedule_pass_role" {
  count = local.enable_s3_to_azure_scheduled_tasks ? 1 : 0

  role       = aws_iam_role.infrastructure_s3_to_azure_cloudwatch_schedule[0].name
  policy_arn = aws_iam_policy.infrastructure_s3_to_azure_cloudwatch_schedule_pass_role[0].arn
}

resource "aws_security_group" "infrastructure_s3_to_azure" {
  count = local.enable_s3_to_azure_scheduled_tasks ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("s3-to-azure-sg"), 0, 6)}"
  description = "${local.resource_prefix}-s3-to-azure-sg"
  vpc_id      = local.infrastructure_vpc ? aws_vpc.infrastructure[0].id : null

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_event_rule" "infrastructure_s3_to_azure_scheduled_task" {
  for_each = local.enable_s3_to_azure_scheduled_tasks ? local.s3_to_azure_sync_jobs : {}

  name                = "${local.resource_prefix}-s3-to-azure-${each.key}"
  description         = "Run ${local.resource_prefix}-s3-to-azure-${each.key} task at a scheduled time (${each.value.cron_expression})"
  schedule_expression = each.value.cron_expression
}

resource "aws_cloudwatch_event_target" "infrastructure_s3_to_azure_scheduled_task" {
  for_each = local.enable_s3_to_azure_scheduled_tasks ? local.s3_to_azure_sync_jobs : {}

  target_id = "${local.resource_prefix}-s3-to-azure-${each.key}"
  rule      = aws_cloudwatch_event_rule.infrastructure_s3_to_azure_scheduled_task[each.key].name
  arn       = aws_ecs_cluster.infrastrucutre_utilities[0].arn
  role_arn  = aws_iam_role.infrastructure_s3_to_azure_cloudwatch_schedule[0].arn
  input = jsonencode(merge(
    {
      containerOverrides = [
        {
          name = "s3-to-azure",
          environment = [
            { name = "SOURCE", value = each.value.source_bucket_uri },
            { name = "DESTINATION", value = each.value.destination_url },
            { name = "AZCOPY_AUTO_LOGIN_TYPE", value = "SPN" }
          ]
        }
      ]
    },
    each.value.cpu != null ? { cpu = each.value.cpu } : {},
    each.value.memory != null ? { memory = each.value.memory } : {}
  ))

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.infrastructure_s3_to_azure[0].arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"
    propagate_tags      = "TASK_DEFINITION"

    network_configuration {
      subnets          = local.infrastructure_vpc_network_enable_private ? [for subnet in aws_subnet.infrastructure_private : subnet.id] : local.infrastructure_vpc_network_enable_public ? [for subnet in aws_subnet.infrastructure_public : subnet.id] : []
      assign_public_ip = local.infrastructure_vpc_network_enable_private ? false : local.infrastructure_vpc_network_enable_public ? true : false
      security_groups = [
        aws_security_group.infrastructure_s3_to_azure[0].id,
      ]
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.infrastructure_s3_to_azure_cloudwatch_schedule_ecs_run_task,
    aws_iam_role_policy_attachment.infrastructure_s3_to_azure_cloudwatch_schedule_pass_role,
  ]
}
