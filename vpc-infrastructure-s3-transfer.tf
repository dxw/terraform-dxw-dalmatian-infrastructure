resource "aws_s3_bucket" "infrastructure_vpc_transfer" {
  count = local.enable_infrastructure_vpc_transfer_s3_bucket ? 1 : 0

  bucket = "${local.resource_prefix_hash}-vpc-transfer"
}

resource "aws_s3_bucket_policy" "infrastructure_vpc_transfer" {
  count = local.enable_infrastructure_vpc_transfer_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_vpc_transfer[0].id
  policy = templatefile(
    "${path.module}/policies/s3-bucket-policy.json.tpl",
    {
      statement = <<EOT
      [
      ${templatefile("${path.root}/policies/s3-bucket-policy-statements/enforce-tls.json.tpl",
      {
        bucket_arn = aws_s3_bucket.infrastructure_vpc_transfer[0].arn
      }
      )},
      ${templatefile("${path.root}/policies/s3-bucket-policy-statements/vpc-rw.json.tpl",
      {
        bucket_arn = aws_s3_bucket.infrastructure_vpc_transfer[0].arn,
        vpc_ids    = jsonencode(local.infrastructure_vpc_transfer_s3_bucket_access_vpc_ids)
      }
  )}
      ]
      EOT
}
)
}

resource "aws_s3_bucket_public_access_block" "infrastructure_vpc_transfer" {
  count = local.enable_infrastructure_vpc_transfer_s3_bucket ? 1 : 0

  bucket                  = aws_s3_bucket.infrastructure_vpc_transfer[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "infrastructure_vpc_transfer" {
  count = local.enable_infrastructure_vpc_transfer_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_vpc_transfer[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "infrastructure_vpc_transfer" {
  count = local.enable_infrastructure_vpc_transfer_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_vpc_transfer[0].id

  target_bucket = aws_s3_bucket.infrastructure_logs[0].id
  target_prefix = "s3/infrastructure-vpc-transfer"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "infrastructure_vpc_transfer" {
  count = local.enable_infrastructure_vpc_transfer_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.infrastructure_vpc_transfer[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
      sse_algorithm     = local.infrastructure_kms_encryption ? "aws:kms" : "AES256"
    }
  }
}
