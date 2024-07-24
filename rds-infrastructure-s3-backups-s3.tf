resource "aws_s3_bucket" "infrastructure_rds_s3_backups" {
  count = local.enable_infrastructure_rds_backup_to_s3 ? 1 : 0

  bucket = "${local.resource_prefix_hash}-infrastructure-rds-s3-backups"
}

resource "aws_s3_bucket_policy" "infrastructure_rds_s3_backups" {
  count = local.enable_infrastructure_rds_backup_to_s3 ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_rds_s3_backups[0].id
  policy = templatefile(
    "${path.module}/policies/s3-bucket-policy.json.tpl",
    {
      statement = <<EOT
      [
      ${templatefile("${path.root}/policies/s3-bucket-policy-statements/enforce-tls.json.tpl",
      {
        bucket_arn = aws_s3_bucket.infrastructure_rds_s3_backups[0].arn
      }
  )}
      ]
      EOT
}
)
}

resource "aws_s3_bucket_public_access_block" "infrastructure_rds_s3_backups" {
  count = local.enable_infrastructure_rds_backup_to_s3 ? 1 : 0

  bucket                  = aws_s3_bucket.infrastructure_rds_s3_backups[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "infrastructure_rds_s3_backups" {
  count = local.enable_infrastructure_rds_backup_to_s3 ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_rds_s3_backups[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "infrastructure_rds_s3_backups" {
  count = local.enable_infrastructure_rds_backup_to_s3 ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_rds_s3_backups[0].id

  target_bucket = aws_s3_bucket.infrastructure_logs[0].id
  target_prefix = "s3/infrastructure-rds-s3-backups"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "infrastructure_rds_s3_backups" {
  count = local.enable_infrastructure_rds_backup_to_s3 ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_rds_s3_backups[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
      sse_algorithm     = local.infrastructure_kms_encryption ? "aws:kms" : "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "infrastructure_rds_s3_backups" {
  count = local.enable_infrastructure_rds_backup_to_s3 && local.infrastructure_rds_backup_to_s3_retention != 0 ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_rds_s3_backups[0].id

  rule {
    id = "all_expire"

    filter {
      prefix = ""
    }

    expiration {
      days = local.infrastructure_rds_backup_to_s3_retention
    }

    status = "Enabled"
  }
}
