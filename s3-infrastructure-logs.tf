resource "aws_s3_bucket" "infrastructure_logs" {
  count = local.enable_infrastructure_logs_bucket ? 1 : 0

  bucket = "${local.resource_prefix_hash}-logs"
}

resource "aws_s3_bucket_ownership_controls" "infrastructure_logs" {
  count = local.enable_infrastructure_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_logs[0].id
  rule {
    object_ownership = contains([for service in local.infrastructure_ecs_cluster_services : service["cloudfront_access_logging_enabled"]], true) ? "BucketOwnerPreferred" : "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_acl" "infrastructure_logs_log_delivery_write" {
  count = local.enable_infrastructure_logs_bucket && contains([for service in local.infrastructure_ecs_cluster_services : service["cloudfront_access_logging_enabled"]], true) ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_logs[0].id
  acl    = "log-delivery-write"

  depends_on = [
    aws_s3_bucket_ownership_controls.infrastructure_logs,
  ]
}

resource "aws_s3_bucket_policy" "infrastructure_logs" {
  count = local.enable_infrastructure_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_logs[0].id
  policy = templatefile(
    "${path.module}/policies/s3-bucket-policy.json.tpl",
    {
      statement = <<EOT
      [
      ${templatefile("${path.root}/policies/s3-bucket-policy-statements/enforce-tls.json.tpl", { bucket_arn = aws_s3_bucket.infrastructure_logs[0].arn })},
      ${templatefile("${path.root}/policies/s3-bucket-policy-statements/log-delivery-access.json.tpl", {
      log_bucket_arn = aws_s3_bucket.infrastructure_logs[0].arn
      source_arns    = jsonencode(local.logs_bucket_source_arns)
      account_id     = local.aws_account_id
})}
      ]
      EOT
}
)
}

resource "aws_s3_bucket_public_access_block" "infrastructure_logs" {
  count = local.enable_infrastructure_logs_bucket ? 1 : 0

  bucket                  = aws_s3_bucket.infrastructure_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "infrastructure_logs" {
  count = local.enable_infrastructure_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# because infrastructure_kms_encryption is only true when multiple other
# vars are true, tfsec can't figure out that this will actually have kms encryption when
# enabled
#tfsec:ignore:aws-s3-encryption-customer-key tfsec:ignore:aws-s3-enable-bucket-encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "infrastructure_logs" {
  count = local.enable_infrastructure_logs_bucket ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_logs[0].id

  dynamic "rule" {
    for_each = local.infrastructure_kms_encryption ? [1] : []
    content {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.infrastructure[0].arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  dynamic "rule" {
    for_each = local.infrastructure_kms_encryption ? [] : [1]
    content {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count = local.enable_infrastructure_logs_bucket && local.infrastructure_logging_bucket_retention != 0 ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_logs[0].id

  rule {
    id = "all_expire"

    filter {
      prefix = ""
    }

    expiration {
      days = local.infrastructure_logging_bucket_retention
    }

    status = "Enabled"
  }
}
