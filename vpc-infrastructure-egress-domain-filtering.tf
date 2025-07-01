# Private egress runs private subnet -> firewall endpoint -> NAT gateway ->
# internet gateway. The firewall needs symmetric routing, so return traffic
# from the NAT gateway must come back through the endpoint. That needs a
# route for the private subnets on the NAT gateway's route table, which
# cannot be the public route table without also sending ALB-to-task traffic
# through the firewall one way only. Both the endpoint and the NAT gateway
# therefore get dedicated subnets, in the AZ the single NAT gateway already
# uses.

resource "aws_subnet" "infrastructure_egress_domain_filtering_firewall" {
  count = local.enable_infrastructure_vpc_egress_domain_filtering ? 1 : 0

  vpc_id            = aws_vpc.infrastructure[0].id
  availability_zone = "${local.aws_region}${local.infrastructure_vpc_egress_domain_filtering_availability_zone}"
  cidr_block        = cidrsubnet(local.infrastructure_vpc_egress_domain_filtering_cidr, 4, 0)

  tags = {
    Name = "${local.resource_prefix}-infrastructure-egress-firewall"
  }
}

resource "aws_subnet" "infrastructure_egress_domain_filtering_nat" {
  count = local.enable_infrastructure_vpc_egress_domain_filtering ? 1 : 0

  vpc_id            = aws_vpc.infrastructure[0].id
  availability_zone = "${local.aws_region}${local.infrastructure_vpc_egress_domain_filtering_availability_zone}"
  cidr_block        = cidrsubnet(local.infrastructure_vpc_egress_domain_filtering_cidr, 4, 1)

  tags = {
    Name = "${local.resource_prefix}-infrastructure-egress-nat"
  }
}

# The public NACL keeps applying to NAT traffic exactly as it did when the
# NAT gateway sat in a public subnet, so any public egress lockdown still holds
resource "aws_network_acl_association" "infrastructure_egress_domain_filtering_firewall" {
  count = local.enable_infrastructure_vpc_egress_domain_filtering ? 1 : 0

  network_acl_id = aws_network_acl.infrastructure_public[0].id
  subnet_id      = aws_subnet.infrastructure_egress_domain_filtering_firewall[0].id
}

resource "aws_network_acl_association" "infrastructure_egress_domain_filtering_nat" {
  count = local.enable_infrastructure_vpc_egress_domain_filtering ? 1 : 0

  network_acl_id = aws_network_acl.infrastructure_public[0].id
  subnet_id      = aws_subnet.infrastructure_egress_domain_filtering_nat[0].id
}

resource "aws_route_table" "infrastructure_egress_domain_filtering_firewall" {
  count = local.enable_infrastructure_vpc_egress_domain_filtering ? 1 : 0

  vpc_id = aws_vpc.infrastructure[0].id

  tags = {
    Name = "${local.resource_prefix}-infrastructure-egress-firewall"
  }
}

resource "aws_route" "infrastructure_egress_domain_filtering_firewall_nat_gateway" {
  count = local.enable_infrastructure_vpc_egress_domain_filtering ? 1 : 0

  route_table_id         = aws_route_table.infrastructure_egress_domain_filtering_firewall[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.infrastructure[0].id
}

resource "aws_route_table_association" "infrastructure_egress_domain_filtering_firewall" {
  count = local.enable_infrastructure_vpc_egress_domain_filtering ? 1 : 0

  subnet_id      = aws_subnet.infrastructure_egress_domain_filtering_firewall[0].id
  route_table_id = aws_route_table.infrastructure_egress_domain_filtering_firewall[0].id
}

resource "aws_route_table" "infrastructure_egress_domain_filtering_nat" {
  count = local.enable_infrastructure_vpc_egress_domain_filtering ? 1 : 0

  vpc_id = aws_vpc.infrastructure[0].id

  tags = {
    Name = "${local.resource_prefix}-infrastructure-egress-nat"
  }
}

resource "aws_route" "infrastructure_egress_domain_filtering_nat_internet_gateway" {
  count = local.enable_infrastructure_vpc_egress_domain_filtering ? 1 : 0

  route_table_id         = aws_route_table.infrastructure_egress_domain_filtering_nat[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.infrastructure_public[0].id
}

# Routes more specific than the VPC local route must match a subnet CIDR
# exactly, so there is one per private subnet rather than one for the
# private half of the VPC
resource "aws_route" "infrastructure_egress_domain_filtering_nat_private_return" {
  for_each = local.enable_infrastructure_vpc_egress_domain_filtering ? local.infrastructure_vpc_network_availability_zones : []

  route_table_id         = aws_route_table.infrastructure_egress_domain_filtering_nat[0].id
  destination_cidr_block = aws_subnet.infrastructure_private[each.value].cidr_block
  vpc_endpoint_id        = local.infrastructure_vpc_egress_domain_filtering_endpoint_id
}

resource "aws_route_table_association" "infrastructure_egress_domain_filtering_nat" {
  count = local.enable_infrastructure_vpc_egress_domain_filtering ? 1 : 0

  subnet_id      = aws_subnet.infrastructure_egress_domain_filtering_nat[0].id
  route_table_id = aws_route_table.infrastructure_egress_domain_filtering_nat[0].id
}

resource "aws_networkfirewall_rule_group" "infrastructure_egress_domain_filtering" {
  count = local.enable_infrastructure_vpc_egress_domain_filtering ? 1 : 0

  # Capacity cannot change after creation, and a domain list uses roughly
  # one unit per domain per target type, so leave plenty of headroom
  capacity = 1000
  name     = "${local.resource_prefix}-infrastructure-egress-domain-filtering"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets              = local.infrastructure_vpc_egress_domain_filtering_domains
      }
    }
  }
}

resource "aws_networkfirewall_firewall_policy" "infrastructure_egress_domain_filtering" {
  count = local.enable_infrastructure_vpc_egress_domain_filtering ? 1 : 0

  name = "${local.resource_prefix}-infrastructure-egress-domain-filtering"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.infrastructure_egress_domain_filtering[0].arn
    }
  }
}

resource "aws_networkfirewall_firewall" "infrastructure_egress_domain_filtering" {
  count = local.enable_infrastructure_vpc_egress_domain_filtering ? 1 : 0

  name                = "${local.resource_prefix}-infrastructure-egress-domain-filtering"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.infrastructure_egress_domain_filtering[0].arn
  vpc_id              = aws_vpc.infrastructure[0].id

  subnet_mapping {
    subnet_id = aws_subnet.infrastructure_egress_domain_filtering_firewall[0].id
  }
}

resource "aws_cloudwatch_log_group" "infrastructure_egress_domain_filtering" {
  count = local.enable_infrastructure_vpc_egress_domain_filtering ? 1 : 0

  # Vended log deliveries add to the account's CloudWatch Logs resource
  # policy unless the group is under /aws/vendedlogs/
  name              = "/aws/vendedlogs/${local.resource_prefix}-infrastructure-egress-domain-filtering"
  retention_in_days = local.infrastructure_vpc_egress_domain_filtering_log_retention
  kms_key_id        = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
}

resource "aws_networkfirewall_logging_configuration" "infrastructure_egress_domain_filtering" {
  count = local.enable_infrastructure_vpc_egress_domain_filtering ? 1 : 0

  firewall_arn = aws_networkfirewall_firewall.infrastructure_egress_domain_filtering[0].arn

  logging_configuration {
    log_destination_config {
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
      log_destination = {
        logGroup = aws_cloudwatch_log_group.infrastructure_egress_domain_filtering[0].name
      }
    }
  }
}
