resource "aws_cloudwatch_log_group" "infrastructure_vpc_flow_logs" {
  count = local.infrastructure_vpc_flow_logs_cloudwatch_logs ? 1 : 0

  name              = "${local.resource_prefix}-infrastructure-vpc-flow-logs"
  retention_in_days = local.infrastructure_vpc_flow_logs_retention
  kms_key_id        = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  skip_destroy      = true
}

resource "aws_iam_role" "infrastructure_vpc_flow_logs" {
  count = local.infrastructure_vpc_flow_logs_cloudwatch_logs ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("infrastructure-vpc-flow-logs"), 0, 6)}"
  description = "${local.resource_prefix}-infrastructure-vpc-flow-logs"
  assume_role_policy = templatefile("${path.root}/policies/assume-roles/service-principle-standard.json.tpl", {
    services = jsonencode(["vpc-flow-logs.amazonaws.com"])
  })
}

resource "aws_iam_role_policy" "infrastructure_vpc_flow_logs_allow_cloudwatch_rw" {
  count = local.infrastructure_vpc_flow_logs_cloudwatch_logs ? 1 : 0

  name   = "${local.resource_prefix}-vpc-flow-logs-cloudwatch-logs-rw"
  role   = aws_iam_role.infrastructure_vpc_flow_logs[0].id
  policy = templatefile("${path.root}/policies/cloudwatch-logs-rw.json.tpl", {})
}

resource "aws_flow_log" "infrastructure_vpc_flow_logs_cloudwatch" {
  count = local.infrastructure_vpc_flow_logs_cloudwatch_logs ? 1 : 0

  iam_role_arn    = aws_iam_role.infrastructure_vpc_flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.infrastructure_vpc_flow_logs[0].arn
  traffic_type    = local.infrastructure_vpc_flow_logs_traffic_type
  vpc_id          = aws_vpc.infrastructure[0].id
}
