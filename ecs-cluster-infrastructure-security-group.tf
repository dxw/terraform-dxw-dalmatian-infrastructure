resource "aws_security_group" "infrastructure_ecs_cluster_container_instances" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  name        = "${local.resource_prefix}-infrastructure-ecs-cluster-container-instances"
  description = "Infrastructure ECS cluster container instances"
  vpc_id      = aws_vpc.infrastructure[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_container_instances_ingress_tcp" {
  count = local.enable_infrastructure_ecs_cluster && local.infrastructure_vpc_network_enable_public ? 1 : 0

  description              = "Allow container port tcp ingress from ALB if launched, otherwise from Public Subnets"
  type                     = "ingress"
  from_port                = 32768
  to_port                  = 65535
  protocol                 = "tcp"
  cidr_blocks              = length(local.infrastructure_ecs_cluster_services) == 0 ? [for subnet in aws_subnet.infrastructure_public : subnet.cidr_block] : null
  source_security_group_id = length(local.infrastructure_ecs_cluster_services) > 0 ? aws_security_group.infrastructure_ecs_cluster_service_alb[0].id : null
  security_group_id        = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_container_instances_ingress_udp" {
  count = local.enable_infrastructure_ecs_cluster && local.infrastructure_vpc_network_enable_public ? 1 : 0

  description              = "Allow container port udp ingress from ALB if launched, otherwise from Public Subnets"
  type                     = "ingress"
  from_port                = 32768
  to_port                  = 65535
  protocol                 = "udp"
  cidr_blocks              = length(local.infrastructure_ecs_cluster_services) == 0 ? [for subnet in aws_subnet.infrastructure_public : subnet.cidr_block] : null
  source_security_group_id = length(local.infrastructure_ecs_cluster_services) > 0 ? aws_security_group.infrastructure_ecs_cluster_service_alb[0].id : null
  security_group_id        = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_container_instances_egress_https_tcp" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  description = "Allow HTTPS tcp outbound"
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_container_instances_egress_https_udp" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  description = "Allow HTTPS udp outbound"
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "udp"
  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_container_instances_egress_dns_tcp" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

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
  security_group_id = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_container_instances_egress_dns_udp" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

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
  security_group_id = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_container_instances_egress_nfs_tcp" {
  count = local.enable_infrastructure_ecs_cluster && local.enable_infrastructure_ecs_cluster_efs ? 1 : 0

  description              = "Allow NFS tcp outbound to EFS security group"
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.infrastructure_ecs_cluster_efs[0].id
  security_group_id        = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_container_instances_egress_rds" {
  for_each = local.enable_infrastructure_ecs_cluster ? local.infrastructure_rds : {}

  description              = "Allow ${each.value["engine"]} tcp outbound to RDS security group"
  type                     = "egress"
  from_port                = local.rds_ports[each.value["engine"]]
  to_port                  = local.rds_ports[each.value["engine"]]
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.infrastructure_rds[each.key].id
  security_group_id        = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
}
