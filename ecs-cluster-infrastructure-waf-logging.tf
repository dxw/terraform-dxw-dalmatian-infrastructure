resource "aws_cloudwatch_log_group" "infrastructure_ecs_cluster_waf" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_wafs : k => v if v["logging"] != null ? v["logging"]["enabled"] : false
  }

  provider = aws.useast1

  # CloudFront-scope WAF logs must land in us-east-1 under this prefix. The
  # infrastructure KMS key is in eu-west-2, which CloudWatch Logs cannot use
  # from another region, so the group uses the AWS-managed encryption.
  name              = "aws-waf-logs-${local.resource_prefix}-${each.key}"
  retention_in_days = each.value["logging"]["retention"]
}

resource "aws_cloudwatch_log_resource_policy" "infrastructure_ecs_cluster_waf" {
  count = length(aws_cloudwatch_log_group.infrastructure_ecs_cluster_waf) > 0 ? 1 : 0

  provider = aws.useast1

  policy_name = "aws-waf-logs-${local.resource_prefix}"
  policy_document = templatefile("${path.root}/policies/waf-logs-resource-policy.json.tpl", {
    aws_account_id  = local.aws_account_id
    resource_prefix = local.resource_prefix
  })
}

resource "aws_wafv2_web_acl_logging_configuration" "infrastructure_ecs_cluster" {
  for_each = aws_cloudwatch_log_group.infrastructure_ecs_cluster_waf

  provider = aws.useast1

  log_destination_configs = [each.value.arn]
  resource_arn            = aws_wafv2_web_acl.infrastructure_ecs_cluster[each.key].arn

  # WAF logs every request header. Session cookies and bearer tokens must
  # not sit in a log group readable by anyone with logs:GetLogEvents.
  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  depends_on = [aws_cloudwatch_log_resource_policy.infrastructure_ecs_cluster_waf]
}
