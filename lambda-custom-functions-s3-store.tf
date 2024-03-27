resource "aws_s3_bucket" "lambda_custom_functions_store" {
  count = local.enable_lambda_functions_s3_store ? 1 : 0

  bucket = "${local.resource_prefix_hash}-lambda-custom-functions"
}

resource "aws_s3_bucket_policy" "lambda_custom_functions_store" {
  count = local.enable_lambda_functions_s3_store ? 1 : 0

  bucket = aws_s3_bucket.lambda_custom_functions_store[0].id
  policy = templatefile(
    "${path.module}/policies/s3-bucket-policy.json.tpl",
    {
      statement = <<EOT
      [
      ${templatefile("${path.root}/policies/s3-bucket-policy-statements/enforce-tls.json.tpl",
      {
        bucket_arn = aws_s3_bucket.lambda_custom_functions_store[0].arn
      }
  )}
      ]
      EOT
}
)
}

resource "aws_s3_bucket_public_access_block" "lambda_custom_functions_store" {
  count = local.enable_lambda_functions_s3_store ? 1 : 0

  bucket                  = aws_s3_bucket.lambda_custom_functions_store[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "lambda_custom_functions_store" {
  count = local.enable_lambda_functions_s3_store ? 1 : 0

  bucket = aws_s3_bucket.lambda_custom_functions_store[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "lambda_custom_functions_store" {
  count = local.enable_lambda_functions_s3_store ? 1 : 0

  bucket = aws_s3_bucket.lambda_custom_functions_store[0].id

  target_bucket = aws_s3_bucket.infrastructure_logs[0].id
  target_prefix = "s3/lambda_custom_functions_store"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lambda_custom_functions_store" {
  count = local.enable_lambda_functions_s3_store ? 1 : 0

  bucket = aws_s3_bucket.lambda_custom_functions_store[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
      sse_algorithm     = local.infrastructure_kms_encryption ? "aws:kms" : "AES256"
    }
  }
}
