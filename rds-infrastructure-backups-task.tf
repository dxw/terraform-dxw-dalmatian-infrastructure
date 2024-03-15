# Define a service principal that will be used by ECS
resource "aws_iam_role" "infrastructure_rds_daily_backups_task_execution" {
  for_each = local.infrastructure_rds_backups_enabled

  name        = "${local.resource_prefix}-${substr(sha512("rds-backups-service-task-execution-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-rds-backups-service-task-execution-${each.key}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
}

# Generate an IAM Policy to enable pulling from an ECR
resource "aws_iam_policy" "infrastructure_rds_daily_backups_ecr_pull" {
  for_each = local.infrastructure_rds_backups_enabled

  name        = "${local.resource_prefix}-${substr(sha512("rds-backups-service-task-execution-${each.key}-ecr-pull"), 0, 6)}"
  description = "${local.resource_prefix}-rds-backups-service-task-execution-${each.key}-ecr-pull"
  policy = templatefile(
    "${path.root}/policies/ecr-pull.json.tpl",
    { ecr_repository_arn = aws_ecr_repository.infrastructure_rds_daily_backups[each.key].arn }
  )
}

# Attach the ECR IAM Policy to the service principal
resource "aws_iam_role_policy_attachment" "infrastructure_rds_daily_backups_ecr_pull" {
  for_each = local.infrastructure_rds_backups_enabled

  role       = aws_iam_role.infrastructure_rds_daily_backups_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_daily_backups_ecr_pull[each.key].arn
}

# Generate an IAM Policy to enable writing into a S3 Bucket
resource "aws_iam_policy" "infrastructure_rds_daily_backups_task_execution_s3_write_blobs" {
  for_each = local.infrastructure_rds_backups_enabled

  name        = "${local.resource_prefix}-${substr(sha512("rds-backups-service-task-execution-${each.key}-s3-write-blobs"), 0, 6)}"
  description = "${local.resource_prefix}-rds-backups-service-task-execution-${each.key}-s3-write-blobs"
  policy = templatefile("${path.root}/policies/s3-object-rw.json.tpl", {
    bucket_arn = aws_s3_bucket.infrastructure_rds_daily_backups[each.key].arn
  })
}

# Attach the S3 IAM Policy to the service principal
resource "aws_iam_role_policy_attachment" "infrastructure_rds_daily_backups_task_execution_s3_write_blobs" {
  for_each = local.infrastructure_rds_backups_enabled

  role       = aws_iam_role.infrastructure_rds_daily_backups_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_daily_backups_task_execution_s3_write-blobs[each.key].arn
}

# Generate an IAM Policy to enable KMS Encryption on S3 Blobs
resource "aws_iam_policy" "infrastructure_rds_daily_backups_task_execution_kms_encrypt" {
  for_each = local.infrastructure_kms_encryption ? local.infrastructure_rds_backups_enabled : {}

  name        = "${local.resource_prefix}-${substr(sha512("rds-backuups-service-task-execution-${each.key}-kms-decrypt"), 0, 6)}"
  description = "${local.resource_prefix}-rds-backuups-service-task-execution-${each.key}-kms-decrypt"
  policy = templatefile(
    "${path.root}/policies/kms-encrypt.json.tpl",
    { kms_key_arn = aws_kms_key.infrastructure[0].arn }
  )
}

# Attach the KMS Encrypt Policy to the service principal
resource "aws_iam_role_policy_attachment" "infrastructure_rds_daily_backups_task_execution_kms_encrypt" {
  for_each = local.infrastructure_kms_encryption ? local.infrastructure_rds_backups_enabled : {}

  role       = aws_iam_role.infrastructure_rds_daily_backups_task_execution[each.key].name
  policy_arn = aws_iam_policy.infrastructure_rds_daily_backups_task_execution_kms_encrypt[each.key].arn
}

# Define a task definition that can be executed periodically
resource "aws_ecs_task_definition" "infrastructure_rds_daily_backups" {
  for_each = local.infrastructure_rds_backups_enabled

  family = "${local.resource_prefix_hash}-${each.key}-rds-backups"
  container_definitions = templatefile(
    "./container-definitions/sql-backup.json.tpl",
    {
      image          = aws_ecr_repository.infrastructure_rds_daily_backups[each.key].repository_url
      container_name = "${local.resource_prefix_hash}-${each.key}-rds-backup"
      entrypoint = jsonencode(
        tolist([
          "/bin/bash",
          "-c",
          local.infrastructure_rds_backups_commands[each.engine]
        ])
      )
      environment = []
      secrets = jsonencode({
        "DB_HOSTNAME"          = sensitive(aws_db_instance.infrastructure_rds[each.key].address)
        "DB_ROOT_PASSWORD"     = sensitive(aws_secretsmanager_secret_version.infrastructure_rds_root_password[each.key].secret_string)
        "DB_USER"              = "root"
        "AWS_S3_BUCKET_TARGET" = aws_s3_bucket.infrastructure_rds_daily_backups[each.key].arn
      })
    }
  )
  execution_role_arn = aws_iam_role.infrastructure_rds_daily_backups_task_execution[each.key].arn
  # task_role_arn            = aws_iam_role.infrastructure_ecs_cluster_service_task[each.key].arn
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = 512
  memory                   = 512

  depends_on = [
    aws_iam_role_policy_attachment.infrastructure_rds_daily_backups_ecr_pull,
    # aws_iam_role_policy_attachment.infrastructure_ecs_cluster_service_task_execution_cloudwatch_logs,
    aws_iam_role_policy_attachment.infrastructure_rds_daily_backups_task_execution_s3_write_blobs,
    aws_iam_role_policy_attachment.infrastructure_rds_daily_backups_task_execution_kms_encrypt,
  ]
}
