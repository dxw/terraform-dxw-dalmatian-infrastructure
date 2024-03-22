resource "aws_s3_bucket" "cloudformation_custom_stack_template_store" {
  count = local.enable_cloudformatian_s3_template_store ? 1 : 0

  bucket = "${local.resource_prefix_hash}-cloudformation-custom-stack-templates"
}

resource "aws_s3_bucket_policy" "cloudformation_custom_stack_template_store" {
  count = local.enable_cloudformatian_s3_template_store ? 1 : 0

  bucket = aws_s3_bucket.cloudformation_custom_stack_template_store[0].id
  policy = templatefile(
    "${path.module}/policies/s3-bucket-policy.json.tpl",
    {
      statement = <<EOT
      [
      ${templatefile("${path.root}/policies/s3-bucket-policy-statements/enforce-tls.json.tpl",
      {
        bucket_arn = aws_s3_bucket.cloudformation_custom_stack_template_store[0].arn
      }
  )}
      ]
      EOT
}
)
}

resource "aws_s3_bucket_public_access_block" "cloudformation_custom_stack_template_store" {
  count = local.enable_cloudformatian_s3_template_store ? 1 : 0

  bucket                  = aws_s3_bucket.cloudformation_custom_stack_template_store[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudformation_custom_stack_template_store" {
  count = local.enable_cloudformatian_s3_template_store ? 1 : 0

  bucket = aws_s3_bucket.cloudformation_custom_stack_template_store[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "cloudformation_custom_stack_template_store" {
  count = local.enable_cloudformatian_s3_template_store ? 1 : 0

  bucket = aws_s3_bucket.cloudformation_custom_stack_template_store[0].id

  target_bucket = aws_s3_bucket.infrastructure_logs[0].id
  target_prefix = "s3/cloudformation-custom-stack-templates"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudformation_custom_stack_template_store" {
  count = local.enable_cloudformatian_s3_template_store ? 1 : 0

  bucket = aws_s3_bucket.cloudformation_custom_stack_template_store[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
      sse_algorithm     = local.infrastructure_kms_encryption ? "aws:kms" : "AES256"
    }
  }
}
