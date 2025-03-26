resource "aws_ecs_cluster" "infrastrucutre_rds_tooling" {
  count = local.enable_infrastructure_rds_tooling ? 1 : 0

  name = local.infrastructure_rds_tooling_ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  dynamic "configuration" {
    for_each = local.infrastructure_ecs_cluster_enable_execute_command_logging ? [1] : []
    content {
      execute_command_configuration {
        kms_key_id = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
        logging    = "OVERRIDE"

        log_configuration {
          s3_bucket_encryption_enabled = true
          s3_bucket_name               = aws_s3_bucket.infrastructure_logs[0].id
          s3_key_prefix                = "ecs-exec"
        }
      }
    }
  }
}
