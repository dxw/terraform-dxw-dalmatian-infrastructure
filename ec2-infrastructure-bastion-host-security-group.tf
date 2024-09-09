resource "aws_security_group" "infrastructure_ec2_bastion_host" {
  count = local.enable_infrastructure_bastion_host ? 1 : 0

  name        = "${local.resource_prefix}-infrastructure-ec2-bastion-host"
  description = "Infrastructure EC2 Bastion Host"
  vpc_id      = aws_vpc.infrastructure[0].id
}

resource "aws_security_group_rule" "infrastructure_ec2_bastion_host_egress_https_tcp" {
  count = local.enable_infrastructure_bastion_host ? 1 : 0

  description = "Allow HTTPS tcp outbound"
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.infrastructure_ec2_bastion_host[0].id
}

resource "aws_security_group_rule" "infrastructure_ec2_bastion_host_egress_https_udp" {
  count = local.enable_infrastructure_bastion_host ? 1 : 0

  description = "Allow HTTPS udp outbound"
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "udp"
  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.infrastructure_ec2_bastion_host[0].id
}

resource "aws_security_group_rule" "infrastructure_ec2_bastion_host_egress_dns_tcp" {
  count = local.enable_infrastructure_bastion_host ? 1 : 0

  description = "Allow DNS tcp outbound to AWS"
  type        = "egress"
  from_port   = 53
  to_port     = 53
  protocol    = "tcp"
  cidr_blocks = local.infrastructure_ecs_cluster_publicly_avaialble ? [
    for subnet in aws_subnet.infrastructure_public : subnet.cidr_block
    ] : [
    for subnet in aws_subnet.infrastructure_private : subnet.cidr_block
  ]
  security_group_id = aws_security_group.infrastructure_ec2_bastion_host[0].id
}

resource "aws_security_group_rule" "infrastructure_ec2_bastion_host_egress_dns_udp" {
  count = local.enable_infrastructure_bastion_host ? 1 : 0

  description = "Allow DNS udp outbound to AWS"
  type        = "egress"
  from_port   = 53
  to_port     = 53
  protocol    = "udp"
  cidr_blocks = local.infrastructure_ecs_cluster_publicly_avaialble ? [
    for subnet in aws_subnet.infrastructure_public : subnet.cidr_block
    ] : [
    for subnet in aws_subnet.infrastructure_private : subnet.cidr_block
  ]
  security_group_id = aws_security_group.infrastructure_ec2_bastion_host[0].id
}

resource "aws_security_group_rule" "infrastructure_ec2_bastion_host_egress_rds" {
  for_each = local.enable_infrastructure_bastion_host ? local.infrastructure_rds : {}

  description              = "Allow ${each.value["engine"]} tcp outbound to RDS security group"
  type                     = "egress"
  from_port                = local.rds_ports[each.value["engine"]]
  to_port                  = local.rds_ports[each.value["engine"]]
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.infrastructure_rds[each.key].id
  security_group_id        = aws_security_group.infrastructure_ec2_bastion_host[0].id
}

resource "aws_security_group_rule" "infrastructure_ec2_bastion_host_custom" {
  for_each = local.enable_infrastructure_bastion_host ? local.infrastructure_bastion_host_custom_security_group_rules : {}

  description              = each.value["description"]
  type                     = each.value["type"]
  from_port                = each.value["from_port"]
  to_port                  = each.value["to_port"]
  protocol                 = each.value["protocol"]
  source_security_group_id = each.value["source_security_group_id"] != "" ? each.value["source_security_group_id"] : null
  cidr_blocks              = length(each.value["cidr_blocks"]) > 0 ? each.value["cidr_blocks"] : null
  security_group_id        = aws_security_group.infrastructure_ec2_bastion_host[0].id
}
