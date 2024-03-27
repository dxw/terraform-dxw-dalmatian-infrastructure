resource "aws_security_group" "infrastructure_rds" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-infrastructure-rds-${each.key}"
  description = "Infrastructure RDS"
  vpc_id      = aws_vpc.infrastructure[0].id
}

resource "aws_security_group_rule" "infrastructure_rds_ingress_tcp_ecs_instances" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? local.infrastructure_rds : {}

  description              = "Allow RDS port tcp ingress from ECS instances if launched, otherwise from the subnet"
  type                     = "ingress"
  from_port                = local.rds_ports[each.value["engine"]]
  to_port                  = local.rds_ports[each.value["engine"]]
  protocol                 = "tcp"
  cidr_blocks              = local.enable_infrastructure_ecs_cluster ? null : local.infrastructure_vpc_network_enable_private ? [for subnet in aws_subnet.infrastructure_private : subnet.cidr_block] : local.infrastructure_vpc_network_enable_public ? [for subnet in aws_subnet.infrastructure_public : subnet.cidr_block] : null
  source_security_group_id = local.enable_infrastructure_ecs_cluster ? aws_security_group.infrastructure_ecs_cluster_container_instances[0].id : null
  security_group_id        = aws_security_group.infrastructure_rds[each.key].id
}

resource "aws_security_group_rule" "infrastructure_rds_ingress_tcp_custom_lambda" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? {
    for k, v in merge(flatten([for rds_k, rds_v in local.infrastructure_rds :
      flatten([
        for lambda_k, lambda_v in local.custom_lambda_functions : { "${rds_k}-${lambda_k}" = merge(rds_k, {
          lambda_source_security_group = lambda_v["launch_in_infrastructure_vpc"] == true ? aws_security_group.custom_lambda[lambda_k].id : null
        }) }
      ])
    ])...) : k => v if v["launch_in_infrastructure_vpc"] != null
  } : {}

  description              = "Allow RDS port tcp ingress from Custom Lambdas if launched"
  type                     = "ingress"
  from_port                = local.rds_ports[each.value["engine"]]
  to_port                  = local.rds_ports[each.value["engine"]]
  protocol                 = "tcp"
  cidr_blocks              = local.infrastructure_vpc_network_enable_private ? [for subnet in aws_subnet.infrastructure_private : subnet.cidr_block] : local.infrastructure_vpc_network_enable_public ? [for subnet in aws_subnet.infrastructure_public : subnet.cidr_block] : null
  source_security_group_id = each.value["launch_in_infrastructure_vpc"]
  security_group_id        = aws_security_group.infrastructure_rds[each.key].id
}
