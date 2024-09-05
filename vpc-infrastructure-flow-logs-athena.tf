resource "aws_athena_workgroup" "infrastructure_vpc_flow_logs" {
  count = local.infrastructure_vpc_flow_logs_s3_with_athena ? 1 : 0

  name = "${local.resource_prefix}-infrastructure-vpc-flow-logs"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.infrastructure_logs[0].bucket}/${local.logs_bucket_athena_result_output_dir}/${local.infrastructure_vpc_flow_logs_s3_key_prefix}-vpcflowlogs"

      encryption_configuration {
        encryption_option = local.infrastructure_kms_encryption ? "SSE_KMS" : "SSE_S3"
        kms_key_arn       = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
      }
    }
  }
}
