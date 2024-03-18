# Create a bucket to store exports for a specific RDS instance
resource "aws_s3_bucket" "infrastructure_rds_daily_backups" {
  for_each = local.infrastructure_rds_backups_enabled

  bucket        = "${local.resource_prefix_hash}-${each.key}-rds-backups"
  force_destroy = false
}

# Enforce TLS>1.2 & Blob encryption in the bucket
resource "aws_s3_bucket_policy" "infrastructure_rds_daily_backups" {
  for_each = local.infrastructure_rds_backups_enabled

  bucket = aws_s3_bucket.infrastructure_rds_daily_backups[each.key].id
  policy = templatefile(
    "${path.module}/policies/s3-bucket-policy.json.tpl",
    {
      statement = <<EOT
      [
      ${templatefile("${path.root}/policies/s3-bucket-policy-statements/enforce-tls.json.tpl",
      {
        bucket_arn = aws_s3_bucket.infrastructure_rds_daily_backups[each.key].arn
      }
      )}${local.infrastructure_kms_encryption ? "," : ""}
      ${templatefile("${path.root}/policies/s3-bucket-policy-statements/enforce-kms-encryption.json.tpl",
      {
        bucket_arn = local.infrastructure_kms_encryption ? aws_s3_bucket.infrastructure_rds_daily_backups[each.key].arn : ""
      }
  )}
      ]
      EOT
}
)
}

# Deny all public access policies/ACLs
resource "aws_s3_bucket_public_access_block" "infrastructure_rds_daily_backups" {
  for_each = local.infrastructure_rds_backups_enabled

  bucket = aws_s3_bucket.infrastructure_rds_daily_backups[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for tamper-awareness
resource "aws_s3_bucket_versioning" "infrastructure_rds_daily_backups" {
  for_each = local.infrastructure_rds_backups_enabled

  bucket = aws_s3_bucket.infrastructure_rds_daily_backups[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable audit logging on objects in the bucket
resource "aws_s3_bucket_logging" "infrastructure_rds_daily_backups" {
  for_each = local.infrastructure_rds_backups_enabled

  bucket = aws_s3_bucket.infrastructure_rds_daily_backups[each.key].id

  target_bucket = aws_s3_bucket.infrastructure_logs[0].id
  target_prefix = "s3/infrastructure-rds-daily-backups"
}

# Apply server-side KMS Encryption for the contents of the bucket
# because infrastructure_kms_encryption is only true when multiple other
# vars are true, tfsec can't figure out that this will actually have kms encryption when
# enabled
#tfsec:ignore:aws-s3-encryption-customer-key tfsec:ignore:aws-s3-enable-bucket-encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "infrastructure_rds_daily_backups" {
  for_each = local.infrastructure_rds_backups_enabled

  bucket = aws_s3_bucket.infrastructure_rds_daily_backups[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
      sse_algorithm     = local.infrastructure_kms_encryption ? "aws:kms" : "AES256"
    }
  }
}

# Deploy an object lifecycle rule that deletes items after 90 days
resource "aws_s3_bucket_lifecycle_configuration" "infrastructure_rds_daily_backups" {
  for_each = local.infrastructure_rds_backups_enabled

  bucket = aws_s3_bucket.infrastructure_rds_daily_backups[each.key].id

  rule {
    id = "delete-after-90-days"

    filter {
      prefix = ""
    }

    expiration {
      days = "90"
    }

    status = "Enabled"
  }

  rule {
    id = "transition-to-ia-then-glacier"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    status = "Enabled"
  }
}
