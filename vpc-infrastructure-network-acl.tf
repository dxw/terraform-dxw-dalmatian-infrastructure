resource "aws_default_network_acl" "infrastructure" {
  count = local.infrastructure_vpc ? 1 : 0

  default_network_acl_id = aws_vpc.infrastructure[0].default_network_acl_id
}

resource "aws_network_acl" "infrastructure_public" {
  count = local.infrastructure_vpc && local.infrastructure_vpc_network_enable_public ? 1 : 0

  vpc_id = aws_vpc.infrastructure[0].id

  tags = {
    Name = "${local.resource_prefix}-infrastructure-public"
  }
}

resource "aws_network_acl" "infrastructure_private" {
  count = local.infrastructure_vpc && local.infrastructure_vpc_network_enable_private ? 1 : 0

  vpc_id = aws_vpc.infrastructure[0].id

  tags = {
    Name = "${local.resource_prefix}-infrastructure-private"
  }
}

resource "aws_network_acl_association" "infrastructure_public_subnets" {
  for_each = local.infrastructure_vpc && local.infrastructure_vpc_network_enable_public ? aws_subnet.infrastructure_public : {}

  network_acl_id = aws_network_acl.infrastructure_public[0].id
  subnet_id      = each.value.id
}

resource "aws_network_acl_association" "infrastructure_private_subnets" {
  for_each = local.infrastructure_vpc && local.infrastructure_vpc_network_enable_private ? aws_subnet.infrastructure_private : {}

  network_acl_id = aws_network_acl.infrastructure_private[0].id
  subnet_id      = each.value.id
}

#This will only be used if `infrastructure_vpc_network_acl_egress_lockdown` isn't set
#We would want to allow all traffic for debugging purposes
#tfsec:ignore:aws-ec2-no-excessive-port-access
resource "aws_network_acl_rule" "egress_allow_all_public" {
  count = local.infrastructure_vpc && local.infrastructure_vpc_network_enable_public && !local.infrastructure_vpc_network_acl_egress_lockdown_public ? 1 : 0

  network_acl_id = aws_network_acl.infrastructure_public[0].id
  egress         = true
  rule_number    = 100

  rule_action = "allow"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_block  = "0.0.0.0/0"
}

#tfsec:ignore:aws-ec2-no-excessive-port-access
resource "aws_network_acl_rule" "egress_allow_all_private" {
  count = local.infrastructure_vpc && local.infrastructure_vpc_network_enable_private && !local.infrastructure_vpc_network_acl_egress_lockdown_private ? 1 : 0

  network_acl_id = aws_network_acl.infrastructure_private[0].id
  egress         = true
  rule_number    = 100

  rule_action = "allow"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_block  = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "egress_public" {
  count = local.infrastructure_vpc && local.infrastructure_vpc_network_enable_public ? length(local.infrastructure_vpc_network_acl_egress_custom_rules_public) : 0

  network_acl_id = aws_network_acl.infrastructure_public[0].id
  rule_number    = count.index + 1
  egress         = true
  protocol       = local.infrastructure_vpc_network_acl_egress_custom_rules_public[count.index]["protocol"]
  rule_action    = local.infrastructure_vpc_network_acl_egress_custom_rules_public[count.index]["action"]
  cidr_block     = local.infrastructure_vpc_network_acl_egress_custom_rules_public[count.index]["cidr_block"]
  from_port      = local.infrastructure_vpc_network_acl_egress_custom_rules_public[count.index]["from_port"]
  to_port        = local.infrastructure_vpc_network_acl_egress_custom_rules_public[count.index]["to_port"]
}

resource "aws_network_acl_rule" "egress_private" {
  count = local.infrastructure_vpc && local.infrastructure_vpc_network_enable_private ? length(local.infrastructure_vpc_network_acl_egress_custom_rules_private) : 0

  network_acl_id = aws_network_acl.infrastructure_private[0].id
  rule_number    = count.index + 1
  egress         = true
  protocol       = local.infrastructure_vpc_network_acl_egress_custom_rules_private[count.index]["protocol"]
  rule_action    = local.infrastructure_vpc_network_acl_egress_custom_rules_private[count.index]["action"]
  cidr_block     = local.infrastructure_vpc_network_acl_egress_custom_rules_private[count.index]["cidr_block"]
  from_port      = local.infrastructure_vpc_network_acl_egress_custom_rules_private[count.index]["from_port"]
  to_port        = local.infrastructure_vpc_network_acl_egress_custom_rules_private[count.index]["to_port"]
}

#This will only be used if `infrastructure_vpc_network_acl_ingress_lockdown` isn't set
#We would want to allow all traffic for debugging purposes
#tfsec:ignore:aws-ec2-no-excessive-port-access tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "ingress_allow_all_public" {
  count = local.infrastructure_vpc && local.infrastructure_vpc_network_enable_public && !local.infrastructure_vpc_network_acl_ingress_lockdown_public ? 1 : 0

  network_acl_id = aws_network_acl.infrastructure_public[0].id
  egress         = false
  rule_number    = 100

  rule_action = "allow"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_block  = "0.0.0.0/0"
}

#tfsec:ignore:aws-ec2-no-excessive-port-access tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "ingress_allow_all_private" {
  count = local.infrastructure_vpc && local.infrastructure_vpc_network_enable_private && !local.infrastructure_vpc_network_acl_ingress_lockdown_private ? 1 : 0

  network_acl_id = aws_network_acl.infrastructure_private[0].id
  egress         = false
  rule_number    = 100

  rule_action = "allow"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_block  = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "ingress_public" {
  count = local.infrastructure_vpc && local.infrastructure_vpc_network_enable_public ? length(local.infrastructure_vpc_network_acl_ingress_custom_rules_public) : 0

  network_acl_id = aws_network_acl.infrastructure_public[0].id
  rule_number    = count.index + 1
  egress         = false
  protocol       = local.infrastructure_vpc_network_acl_ingress_custom_rules_public[count.index]["protocol"]
  rule_action    = local.infrastructure_vpc_network_acl_ingress_custom_rules_public[count.index]["action"]
  cidr_block     = local.infrastructure_vpc_network_acl_ingress_custom_rules_public[count.index]["cidr_block"]
  from_port      = local.infrastructure_vpc_network_acl_ingress_custom_rules_public[count.index]["from_port"]
  to_port        = local.infrastructure_vpc_network_acl_ingress_custom_rules_public[count.index]["to_port"]
}

resource "aws_network_acl_rule" "ingress_private" {
  count = local.infrastructure_vpc && local.infrastructure_vpc_network_enable_private ? length(local.infrastructure_vpc_network_acl_ingress_custom_rules_private) : 0

  network_acl_id = aws_network_acl.infrastructure_private[0].id
  rule_number    = count.index + 1
  egress         = false
  protocol       = local.infrastructure_vpc_network_acl_ingress_custom_rules_private[count.index]["protocol"]
  rule_action    = local.infrastructure_vpc_network_acl_ingress_custom_rules_private[count.index]["action"]
  cidr_block     = local.infrastructure_vpc_network_acl_ingress_custom_rules_private[count.index]["cidr_block"]
  from_port      = local.infrastructure_vpc_network_acl_ingress_custom_rules_private[count.index]["from_port"]
  to_port        = local.infrastructure_vpc_network_acl_ingress_custom_rules_private[count.index]["to_port"]
}
