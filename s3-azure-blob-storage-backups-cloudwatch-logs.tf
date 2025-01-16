resource "aws_cloudwatch_log_group" "s3_azure_blob_storage_backups" {
  for_each = local.enable_s3_backup_to_azure_blob_storage ? local.s3_backup_to_azure_blob_storage_source_and_targets : {}

  name              = "${local.resource_prefix}-s3-azure-blob-storage-backups-${each.key}"
  retention_in_days = 30
  kms_key_id        = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  skip_destroy      = true
}
