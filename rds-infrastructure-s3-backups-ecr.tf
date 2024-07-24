resource "aws_ecr_repository" "infrastructure_rds_s3_backups" {
  count = local.enable_infrastructure_rds_backup_to_s3 ? 1 : 0

  name = "${local.resource_prefix}-rds-s3-backups"

  #tfsec:ignore:aws-ecr-enforce-immutable-repository
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = local.infrastructure_kms_encryption ? "KMS" : "AES256"
    kms_key         = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  }

  image_scanning_configuration {
    scan_on_push = true
  }
}
