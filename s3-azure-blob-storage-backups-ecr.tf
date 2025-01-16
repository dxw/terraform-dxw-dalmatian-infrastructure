resource "aws_ecr_repository" "s3_azure_blob_storage_backups" {
  count = local.enable_s3_backup_to_azure_blob_storage ? 1 : 0

  name = "${local.resource_prefix}-s3-azure-blob-storage-backups"

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
