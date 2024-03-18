# Deploy an ECR that holds the Container Images we will use to run the RDS exports
resource "aws_ecr_repository" "infrastructure_rds_daily_backups" {
  for_each = local.infrastructure_rds_backups_enabled

  name = "${local.resource_prefix_hash}-${each.key}-rds-backup"

  encryption_configuration {
    encryption_type = local.infrastructure_kms_encryption ? "KMS" : "AES256"
    kms_key         = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}
