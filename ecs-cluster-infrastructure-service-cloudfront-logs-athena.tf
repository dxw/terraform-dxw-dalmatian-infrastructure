resource "aws_athena_workgroup" "infrastructure_ecs_cluster_service_cloudfront_logs" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["enable_cloudfront"] == true && v["cloudfront_access_logging_enabled"] == true
  }

  name = "${local.resource_prefix}-infrastructure-ecs-cluster-service-${each.key}-logs"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.infrastructure_logs[0].bucket}/${local.logs_bucket_athena_result_output_dir}/${local.resource_prefix}-infrastructure-ecs-cluster-service-${each.key}-cloudfront-logs"

      encryption_configuration {
        encryption_option = local.infrastructure_kms_encryption ? "SSE_KMS" : "SSE_S3"
        kms_key_arn       = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
      }
    }
  }
}
