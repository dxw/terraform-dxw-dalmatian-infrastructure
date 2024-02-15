resource "aws_iam_role" "infrastructure_rds_monitoring" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? {
    for k, v in local.infrastructure_rds : k => v if v["monitoring_interval"] != null && v["monitoring_interval"] != 0
  } : {}

  name        = "${local.resource_prefix}-${substr(sha512("rds-monitoring-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-rds-monitoring-${each.key}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["monitoring.rds.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_rds_monitoring" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? {
    for k, v in local.infrastructure_rds : k => v if v["monitoring_interval"] != null && v["monitoring_interval"] != 0
  } : {}

  name   = "${local.resource_prefix}-rds-monitoring-${each.key}"
  policy = templatefile("${path.root}/policies/rds-enhanced-monitoring.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_rds_monitoring" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? {
    for k, v in local.infrastructure_rds : k => v if v["monitoring_interval"] != null && v["monitoring_interval"] != 0
  } : {}

  role       = aws_iam_role.infrastructure_rds_monitoring[each.key].id
  policy_arn = aws_iam_policy.infrastructure_rds_monitoring[each.key].arn
}
