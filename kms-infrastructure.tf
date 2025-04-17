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
        log_group_arn = local.infrastructure_ecs_cluster_draining_lambda_enabled && local.infrastructure_kms_encryption ? "arn:aws:logs:${local.aws_region}:${local.aws_account_id}:log-group:/aws/lambda/${local.resource_prefix_hash}-ecs-cluster-infrastructure-draining" : ""
      }
      )}${local.infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression != "" && local.infrastructure_kms_encryption ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/cloudwatch-logs-allow.json.tpl",
      {
        log_group_arn = local.infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression != "" && local.infrastructure_kms_encryption ? "arn:aws:logs:${local.aws_region}:${local.aws_account_id}:log-group:/aws/lambda/${local.resource_prefix_hash}-ecs-cluster-infrastructure-instance-refresh" : ""
      }
      )}${local.enable_infrastructure_ecs_cluster_pending_task_alert && local.infrastructure_kms_encryption ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/cloudwatch-logs-allow.json.tpl",
      {
        log_group_arn = local.enable_infrastructure_ecs_cluster_pending_task_alert && local.infrastructure_kms_encryption ? "arn:aws:logs:${local.aws_region}:${local.aws_account_id}:log-group:/aws/lambda/${local.resource_prefix_hash}-ecs-cluster-infrastructure-pending-task-metric" : ""
      }
      )}${local.enable_infrastructure_ecs_cluster_datadog_agent && local.infrastructure_kms_encryption ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/cloudwatch-logs-allow.json.tpl",
      {
        log_group_arn = local.enable_infrastructure_ecs_cluster_datadog_agent && local.infrastructure_kms_encryption ? "arn:aws:logs:${local.aws_region}:${local.aws_account_id}:log-group:${local.resource_prefix_hash}-infrastructure-ecs-cluster-datadog-agent-logs" : ""
      }
      )}${local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert && local.infrastructure_kms_encryption ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/cloudwatch-logs-allow.json.tpl",
      {
        log_group_arn = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert && local.infrastructure_kms_encryption ? "arn:aws:logs:${local.aws_region}:${local.aws_account_id}:log-group:/aws/lambda/${local.resource_prefix_hash}-ecs-cluster-infrastructure-ecs-asg-diff-metric" : ""
      }
      )}${length(local.infrastructure_ecs_cluster_services) > 0 && local.infrastructure_kms_encryption ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/cloudwatch-logs-allow.json.tpl",
      {
        log_group_arn = length(local.infrastructure_ecs_cluster_services) > 0 && local.infrastructure_kms_encryption ? "arn:aws:logs:${local.aws_region}:${local.aws_account_id}:log-group:${local.resource_prefix}-infrastructure-ecs-cluster-service-logs-*" : ""
      }
      )}${length(local.infrastructure_ecs_cluster_services) > 0 && local.infrastructure_kms_encryption && local.infrastructure_ecs_cluster_enable_execute_command_logging ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/role-allow-encrypt.json.tpl",
      {
        role_arns = jsonencode([
          for k, v in local.infrastructure_ecs_cluster_services : aws_iam_role.infrastructure_ecs_cluster_service_task_execution[k].arn if v["enable_execute_command"] == true && local.infrastructure_ecs_cluster_enable_execute_command_logging
        ])
      }
      )}${length(local.infrastructure_rds) > 0 && local.infrastructure_kms_encryption && local.enable_infrastructure_utilities ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/role-allow-encrypt.json.tpl",
      {
        role_arns = jsonencode([
          for k, v in local.infrastructure_rds : aws_iam_role.infrastructure_utilities_task[k].arn if local.enable_infrastructure_utilities
        ])
      }
      )}${length(local.infrastructure_rds) > 0 && local.infrastructure_kms_encryption && local.enable_infrastructure_utilities ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/cloudwatch-logs-allow.json.tpl",
      {
        log_group_arn = length(local.infrastructure_rds) > 0 && local.infrastructure_kms_encryption && local.enable_infrastructure_utilities ? "arn:aws:logs:${local.aws_region}:${local.aws_account_id}:log-group:${local.resource_prefix}-infrastructure-utilities-*" : ""
      }
      )}${contains([for k, v in local.custom_s3_buckets : (v["cloudfront_dedicated_distribution"] == true || v["cloudfront_infrastructure_ecs_cluster_service"] != null) && (v["create_dedicated_kms_key"] == false || v["create_dedicated_kms_key"] == null)], true) && local.infrastructure_kms_encryption ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/cloudfront-distribution-allow.json.tpl",
      {
        cloudfront_distribution_arns = jsonencode(distinct(concat(
          [for k, v in local.custom_s3_buckets : aws_cloudfront_distribution.custom_s3_buckets[k].arn if v["cloudfront_dedicated_distribution"] == true && (v["create_dedicated_kms_key"] == null || v["create_dedicated_kms_key"] == false)],
          [for k, v in local.custom_s3_buckets : aws_cloudfront_distribution.infrastructure_ecs_cluster_service_cloudfront[v["cloudfront_infrastructure_ecs_cluster_service"]].arn if v["cloudfront_infrastructure_ecs_cluster_service"] != null && (v["create_dedicated_kms_key"] == null || v["create_dedicated_kms_key"] == false)]
        )))
      })}${(local.infrastructure_vpc_flow_logs_s3_with_athena || local.enable_cloudformatian_s3_template_store || contains([for service in local.infrastructure_ecs_cluster_services : service["cloudfront_access_logging_enabled"]], true)) || length(local.custom_s3_buckets) > 0 && local.infrastructure_kms_encryption ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/log-delivery-allow.json.tpl",
      {
        account_id = (local.infrastructure_vpc_flow_logs_s3_with_athena || local.enable_cloudformatian_s3_template_store || contains([for service in local.infrastructure_ecs_cluster_services : service["cloudfront_access_logging_enabled"]], true)) || length(local.custom_s3_buckets) > 0 && local.infrastructure_kms_encryption ? local.aws_account_id : ""
        region     = local.aws_region
      })}${local.enable_infrastructure_vpc_transfer_s3_bucket ? "," : ""}
      ${templatefile("${path.root}/policies/kms-key-policy-statements/vpc-id-and-s3-bucket-allow.json.tpl",
      {
        vpc_ids    = jsonencode(local.infrastructure_vpc_transfer_s3_bucket_access_vpc_ids)
        region     = local.aws_region
        bucket_arn = local.enable_infrastructure_vpc_transfer_s3_bucket ? aws_s3_bucket.infrastructure_vpc_transfer[0].arn : ""
      }
  )}${local.infrastructure_kms_key_policy_statements != "" ? ",${local.infrastructure_kms_key_policy_statements}" : ""}

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
