resource "aws_cloudwatch_log_group" "infrastructure_utilities" {
  for_each = local.enable_infrastructure_utilities ? local.infrastructure_rds : {}

  name              = "${local.resource_prefix}-infrastructure-utilities-${each.key}"
  retention_in_days = 30
  kms_key_id        = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  skip_destroy      = true
}
