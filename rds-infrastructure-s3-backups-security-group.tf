resource "aws_security_group" "infrastructure_rds_s3_backups_scheduled_task" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-infrastructure-rds-s3-backups-scheduled-task-${each.key}"
  description = "Infrastructure RDS S3 backups scheduled task"
  vpc_id      = aws_vpc.infrastructure[0].id
}

resource "aws_security_group_rule" "infrastructure_rds_s3_backups_scheduled_task_egress_https_tcp" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  description = "Allow HTTPS tcp outbound"
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.infrastructure_rds_s3_backups_scheduled_task[each.key].id
}

resource "aws_security_group_rule" "infrastructure_rds_s3_backups_scheduled_task_egress_https_udp" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  description = "Allow HTTPS udp outbound"
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "udp"
  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.infrastructure_rds_s3_backups_scheduled_task[each.key].id
}

resource "aws_security_group_rule" "infrastructure_rds_s3_backups_scheduled_task_egress_dns_tcp" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

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
  security_group_id = aws_security_group.infrastructure_rds_s3_backups_scheduled_task[each.key].id
}

resource "aws_security_group_rule" "infrastructure_rds_s3_backups_scheduled_task_egress_dns_udp" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

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
  security_group_id = aws_security_group.infrastructure_rds_s3_backups_scheduled_task[each.key].id
}

resource "aws_security_group_rule" "infrastructure_rds_s3_backups_scheduled_task_egress_rds" {
  for_each = local.enable_infrastructure_rds_backup_to_s3 ? local.infrastructure_rds : {}

  description              = "Allow ${each.value["engine"]} tcp outbound to RDS security group"
  type                     = "egress"
  from_port                = local.rds_ports[each.value["engine"]]
  to_port                  = local.rds_ports[each.value["engine"]]
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.infrastructure_rds[each.key].id
  security_group_id        = aws_security_group.infrastructure_rds_s3_backups_scheduled_task[each.key].id
}
