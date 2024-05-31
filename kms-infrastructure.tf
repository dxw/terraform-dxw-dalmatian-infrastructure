resource "aws_kms_key" "infrastructure" {
  count = local.infrastructure_kms_encryption ? 1 : 0

  description             = "${local.resource_prefix} infrastructure kms key"
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
      )}${local.infrastructure_vpc_flow_logs_cloudwatch_logs && local.infrastructure_kms_encryption ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/cloudwatch-logs-allow.json.tpl",
      {
        log_group_arn = local.infrastructure_vpc_flow_logs_cloudwatch_logs && local.infrastructure_kms_encryption ? "arn:aws:logs:${local.aws_region}:${local.aws_account_id}:log-group:${local.resource_prefix}-infrastructure-vpc-flow-logs" : ""
      }
      )}${local.infrastructure_ecs_cluster_draining_lambda_enabled && local.infrastructure_kms_encryption ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/cloudwatch-logs-allow.json.tpl",
      {
        log_group_arn = local.infrastructure_ecs_cluster_draining_lambda_enabled && local.infrastructure_kms_encryption ? "arn:aws:logs:${local.aws_region}:${local.aws_account_id}:log-group:/aws/lambda/${local.resource_prefix}-ecs-cluster-infrastructure-draining" : ""
      }
      )}${length(local.infrastructure_ecs_cluster_services) > 0 && local.infrastructure_kms_encryption ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/cloudwatch-logs-allow.json.tpl",
      {
        log_group_arn = length(local.infrastructure_ecs_cluster_services) > 0 && local.infrastructure_kms_encryption ? "arn:aws:logs:${local.aws_region}:${local.aws_account_id}:log-group:${local.resource_prefix}-infrastructure-ecs-cluster-service-logs-*" : ""
      }
      )}${contains([for k, v in local.custom_s3_buckets : (v["cloudfront_dedicated_distribution"] == true || v["cloudfront_infrastructure_ecs_cluster_service"] != null) && v["create_dedicated_kms_key"] == false ? true : false], true) && local.infrastructure_kms_encryption ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/cloudfront-distribution-allow.json.tpl",
      {
        cloudfront_distribution_arns = jsonencode(distinct(concat(
          [for k, v in local.custom_s3_buckets : aws_cloudfront_distribution.custom_s3_buckets[k].arn if v["cloudfront_dedicated_distribution"] == true && v["create_dedicated_kms_key"] == false],
          [for k, v in local.custom_s3_buckets : aws_cloudfront_distribution.infrastructure_ecs_cluster_service_cloudfront[v["cloudfront_infrastructure_ecs_cluster_service"]].arn if v["cloudfront_infrastructure_ecs_cluster_service"] != null && v["create_dedicated_kms_key"] == false]
        )))
      })}${(local.infrastructure_vpc_flow_logs_s3_with_athena || local.enable_cloudformatian_s3_template_store || contains([for service in local.infrastructure_ecs_cluster_services : service["cloudfront_access_logging_enabled"]], true)) && local.infrastructure_kms_encryption ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/log-delivery-allow.json.tpl",
      {
        account_id = (local.infrastructure_vpc_flow_logs_s3_with_athena || local.enable_cloudformatian_s3_template_store || contains([for service in local.infrastructure_ecs_cluster_services : service["cloudfront_access_logging_enabled"]], true)) || length(local.custom_s3_buckets) > 0 && local.infrastructure_kms_encryption ? local.aws_account_id : ""
        region     = local.aws_region
      })}${local.enable_infrastructure_vpc_transfer_s3_bucket ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/vpc-id-and-s3-bucket-allow.json.tpl",
      {
        vpc_ids    = jsonencode(local.infrastructure_vpc_transfer_s3_bucket_access_vpc_ids)
        region     = local.aws_region
        bucket_arn = aws_s3_bucket.infrastructure_vpc_transfer[0].arn
      }
  )}

      ]
      EOT
}
)
}

resource "aws_kms_alias" "infrastructure" {
  count = local.infrastructure_kms_encryption ? 1 : 0

  name          = "alias/${local.resource_prefix}-infrastructure"
  target_key_id = aws_kms_key.infrastructure[0].key_id
}
