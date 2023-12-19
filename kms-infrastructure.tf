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
        log_group_arn = local.infrastructure_ecs_cluster_draining_lambda_enabled && local.infrastructure_kms_encryption ? "arn:aws:logs:${local.aws_region}:${local.aws_account_id}:log-group:/aws/lambda/${local.project_name}-ecs-cluster-infrastructure-draining" : ""
      }
      )}${local.infrastructure_vpc_flow_logs_s3_with_athena && local.infrastructure_kms_encryption ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/log-delivery-allow.json.tpl",
      {
        account_id = local.infrastructure_vpc_flow_logs_s3_with_athena && local.infrastructure_kms_encryption ? local.aws_account_id : ""
        region     = local.aws_region
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
