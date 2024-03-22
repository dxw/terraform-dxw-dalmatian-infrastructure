resource "aws_security_group" "infrastructure_elasticache" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? local.infrastructure_elasticache : {}

  name        = "${local.resource_prefix}-infrastructure-elasticache-${each.key}"
  description = "Infrastructure ElastiCache"
  vpc_id      = aws_vpc.infrastructure[0].id
}

resource "aws_security_group_rule" "infrastructure_elasticache_ingress_tcp" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? local.infrastructure_elasticache : {}

  description              = "Allow ElastiCache port tcp ingress from ECS instances if launched, otherwise from the subnet"
  type                     = "ingress"
  from_port                = local.elasticache_ports[each.value["engine"]]
  to_port                  = local.elasticache_ports[each.value["engine"]]
  protocol                 = "tcp"
  cidr_blocks              = local.enable_infrastructure_ecs_cluster ? null : local.infrastructure_vpc_network_enable_private ? [for subnet in aws_subnet.infrastructure_private : subnet.cidr_block] : local.infrastructure_vpc_network_enable_public ? [for subnet in aws_subnet.infrastructure_public : subnet.cidr_block] : null
  source_security_group_id = local.enable_infrastructure_ecs_cluster ? aws_security_group.infrastructure_ecs_cluster_container_instances[0].id : null
  security_group_id        = aws_security_group.infrastructure_elasticache[each.key].id
}
