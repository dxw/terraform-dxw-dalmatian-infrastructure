resource "aws_cloudwatch_log_group" "infrastructure_rds_exports" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? toset(flatten([for k, v in local.infrastructure_rds :
    [
      for type in v["cloudwatch_logs_export_types"] : "${v["type"]}/${local.resource_prefix_hash}-${k}/${type}"
    ]
    if v["cloudwatch_logs_export_types"] != null
  ])) : []

  name              = "/aws/rds/${each.value}"
  retention_in_days = 30
  kms_key_id        = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].id : null
}

resource "aws_cloudwatch_log_group" "infrastructure_rds_tooling" {
  for_each = local.enable_infrastructure_rds_tooling ? local.infrastructure_rds : {}

  name              = "${local.resource_prefix}-infrastructure-rds-tooling-${each.key}"
  retention_in_days = 30
  kms_key_id        = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  skip_destroy      = true
}
