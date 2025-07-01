resource "aws_networkfirewall_rule_group" "egress_domain_filtering" {
  count = local.infrastructure_vpc_enable_egress_domain_filtering ? 1 : 0

  capacity = 100
  name     = "${local.resource_prefix}-infrastructure-egress-domain-filtering"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_string = templatefile(
        "${path.root}/network-firewall-rules/domain-filtering.tpl",
        {
          domains = local.infrastructure_vpc_egress_domain_filtering_allow_list
        }
      )
    }
  }
}

resource "aws_networkfirewall_firewall_policy" "egress_domain_filtering" {
  count = local.infrastructure_vpc_enable_egress_domain_filtering ? 1 : 0

  name = "${local.resource_prefix}-infrastructure-egress-domain-filtering"

  stateless_default_actions          = ["aws:forward_to_sfe"]
  stateless_fragment_default_actions = ["aws:forward_to_sfe"]

  stateful_rule_group_reference {
    resource_arn = aws_networkfirewall_rule_group.egress_domain_filtering[0].arn
  }
}

resource "aws_networkfirewall_firewall" "egress_domain_filtering" {
  count = local.infrastructure_vpc_enable_egress_domain_filtering ? 1 : 0

  name                = "${local.resource_prefix}-infrastructure-egress-domain-filtering"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.egress_domain_filtering[0].arn
  vpc_id              = aws_vpc.infrastructure[0].id

  dynamic "subnet_mapping" {
    for_each = local.infrastructure_vpc_network_enable_private ? [for subnet in aws_subnet.infrastructure_private : subnet.id] : local.infrastructure_vpc_network_enable_public ? [for subnet in aws_subnet.infrastructure_public : subnet.id] : null
    content {
      subnet_id = subnet_mapping.value
    }
  }
}

resource "aws_cloudwatch_log_group" "egress_domain_filtering" {
  count = local.infrastructure_vpc_enable_egress_domain_filtering ? 1 : 0

  name = "/aws/network-firewall/${local.resource_prefix}-infrastructure-egress-domain-filtering"
}

resource "aws_networkfirewall_logging_configuration" "egress_domain_filtering" {
  count = local.infrastructure_vpc_enable_egress_domain_filtering ? 1 : 0

  firewall_arn = aws_networkfirewall_firewall.egress_domain_filtering[0].arn

  logging_configuration {
    log_destination_config {
      log_type = "FLOW"
      log_destination = {
        logGroup = aws_cloudwatch_log_group.egress_domain_filtering[0].name
      }
    }
  }
}
