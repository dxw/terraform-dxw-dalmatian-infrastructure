resource "aws_kms_key" "custom_s3_buckets" {
  for_each = {
    for k, v in local.custom_s3_buckets : k => v if v["create_dedicated_kms_key"] == true
  }

  description             = "${local.resource_prefix} ${each.key} S3 bucket kms key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = templatefile(
    "${path.root}/policies/kms-key-policy.json.tpl",
    {
      statement = <<EOT
      [
      ${templatefile("${path.root}/policies/kms-key-policy-statements/root-allow-all.json.tpl",
      {
        aws_account_id = local.aws_account_id
      }
      )}${each.value["cloudfront_dedicated_distribution"] == true || each.value["cloudfront_infrastructure_ecs_cluster_service"] != null ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/cloudfront-distribution-allow.json.tpl",
      {
        cloudfront_distribution_arns = jsonencode(distinct(concat(
          each.value["cloudfront_dedicated_distribution"] == true ? [aws_cloudfront_distribution.custom_s3_buckets[each.key].arn] : [],
          each.value["cloudfront_infrastructure_ecs_cluster_service"] != null ? [aws_cloudfront_distribution.infrastructure_ecs_cluster_service_cloudfront[each.value["cloudfront_infrastructure_ecs_cluster_service"]].arn] : []
        )))
      }
  )}
      ]
      EOT
}
)
}

resource "aws_kms_alias" "custom_s3_buckets" {
  for_each = {
    for k, v in local.custom_s3_buckets : k => v if v["create_dedicated_kms_key"] == true
  }

  name          = "alias/${local.resource_prefix}-${each.key}-custom-bucket"
  target_key_id = aws_kms_key.custom_s3_buckets[each.key].key_id
}
