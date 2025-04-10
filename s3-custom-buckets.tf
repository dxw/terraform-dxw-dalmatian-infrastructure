resource "aws_s3_bucket" "custom" {
  for_each = local.custom_s3_buckets

  bucket        = each.key
  force_destroy = false
}

resource "aws_s3_bucket_policy" "custom" {
  for_each = local.custom_s3_buckets

  bucket = aws_s3_bucket.custom[each.key].id
  policy = templatefile(
    "${path.module}/policies/s3-bucket-policy.json.tpl",
    {
      statement = <<EOT
      [
      ${templatefile("${path.root}/policies/s3-bucket-policy-statements/enforce-tls.json.tpl",
      {
        bucket_arn = aws_s3_bucket.custom[each.key].arn
      }
      )}${contains([for k, v in local.custom_s3_buckets : (v["cloudfront_dedicated_distribution"] == true || v["cloudfront_infrastructure_ecs_cluster_service"] != null) ? true : false], true) && local.infrastructure_kms_encryption ? "," : ""}
      ${templatefile("${path.root}/policies/s3-bucket-policy-statements/cloudfront-distribution-allow.json.tpl",
      {
        bucket_arn = aws_s3_bucket.custom[each.key].arn,
        cloudfront_distribution_arns = jsonencode(distinct(concat(
          [for k, v in local.custom_s3_buckets : aws_cloudfront_distribution.custom_s3_buckets[k].arn if v["cloudfront_dedicated_distribution"] == true],
          [for k, v in local.custom_s3_buckets : aws_cloudfront_distribution.infrastructure_ecs_cluster_service_cloudfront[v["cloudfront_infrastructure_ecs_cluster_service"]].arn if v["cloudfront_infrastructure_ecs_cluster_service"] != null]
        )))
      }
  )}${each.value["custom_bucket_policy_statements"] != null ? ",${each.value["custom_bucket_policy_statements"]}" : ""}
      ]
      EOT
}
)
}

resource "aws_s3_bucket_ownership_controls" "custom" {
  for_each = local.custom_s3_buckets

  bucket = aws_s3_bucket.custom[each.key].id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "custom" {
  for_each = local.custom_s3_buckets

  bucket                  = aws_s3_bucket.custom[each.key].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "custom" {
  for_each = local.custom_s3_buckets

  bucket = aws_s3_bucket.custom[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "custom" {
  for_each = local.custom_s3_buckets

  bucket = aws_s3_bucket.custom[each.key].id

  target_bucket = aws_s3_bucket.infrastructure_logs[0].id
  target_prefix = "s3/custom-buckets/${each.key}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "custom" {
  for_each = local.custom_s3_buckets

  bucket = aws_s3_bucket.custom[each.key].id

  dynamic "rule" {
    for_each = (local.infrastructure_kms_encryption || each.value["create_dedicated_kms_key"] == true) && each.value["use_aes256_encryption"] != true ? [1] : []

    content {
      apply_server_side_encryption_by_default {
        kms_master_key_id = each.value["create_dedicated_kms_key"] == true ? aws_kms_key.custom_s3_buckets[each.key].arn : aws_kms_key.infrastructure[0].arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  dynamic "rule" {
    for_each = (local.infrastructure_kms_encryption || each.value["create_dedicated_kms_key"] == true) && each.value["use_aes256_encryption"] != true ? [] : [1]

    content {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "custom" {
  for_each = {
    for k, v in local.custom_s3_buckets : k => v if v["transition_to_ia_days"] != null || v["transition_to_glacier_days"] != null
  }

  bucket = aws_s3_bucket.custom[each.key].id

  # At least 1 (non-dynamic) rule is required
  rule {
    id = "required-by-terraform-unused-disabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    filter {
      prefix = ""
    }

    status = "Disabled"
  }

  dynamic "rule" {
    for_each = each.value["transition_to_ia_days"] != null ? [1] : []
    content {
      id = "transition-to-ia"

      transition {
        days          = each.value["transition_to_ia_days"]
        storage_class = "STANDARD_IA"
      }

      filter {
        prefix = ""
      }

      status = "Enabled"
    }
  }

  dynamic "rule" {
    for_each = each.value["transition_to_glacier_days"] != null ? [1] : []
    content {
      id = "transition-to-glacier"

      transition {
        days          = each.value["transition_to_glacier_days"]
        storage_class = "GLACIER"
      }

      filter {
        prefix = ""
      }

      status = "Enabled"
    }
  }
}
