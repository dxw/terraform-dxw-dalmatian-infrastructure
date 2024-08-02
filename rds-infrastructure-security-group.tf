resource "aws_security_group" "infrastructure_rds" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-infrastructure-rds-${each.key}"
  description = "Infrastructure RDS"
  vpc_id      = aws_vpc.infrastructure[0].id
}

resource "aws_security_group_rule" "infrastructure_rds_ingress_tcp" {
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

resource "aws_security_group_rule" "infrastructure_rds_s3_backup_task_ingress_tcp" {
  for_each = (local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private) && local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  description              = "Allow RDS port tcp ingress from RDS S3 Backup Scheduled task"
  type                     = "ingress"
  from_port                = local.rds_ports[each.value["engine"]]
  to_port                  = local.rds_ports[each.value["engine"]]
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.infrastructure_rds_s3_backups_scheduled_task[each.key].id
  security_group_id        = aws_security_group.infrastructure_rds[each.key].id
}
