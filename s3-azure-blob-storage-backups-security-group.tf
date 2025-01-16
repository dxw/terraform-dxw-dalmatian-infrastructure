resource "aws_security_group" "s3_azure_blob_storage_backups_scheduled_task" {
  count = local.enable_s3_backup_to_azure_blob_storage ? 1 : 0

  name        = "${local.resource_prefix}-s3-azure-blob-storage-backups-scheduled-task"
  description = "S3 Azure blob storage backups scheduled task"
  vpc_id      = aws_vpc.infrastructure[0].id
}

resource "aws_security_group_rule" "s3_azure_blob_storage_backups_scheduled_task_egress_https_tcp" {
  count = local.enable_s3_backup_to_azure_blob_storage ? 1 : 0

  description = "Allow HTTPS tcp outbound"
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.s3_azure_blob_storage_backups_scheduled_task[0].id
}

resource "aws_security_group_rule" "s3_azure_blob_storage_backups_scheduled_task_egress_https_udp" {
  count = local.enable_s3_backup_to_azure_blob_storage ? 1 : 0

  description = "Allow HTTPS udp outbound"
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "udp"
  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.s3_azure_blob_storage_backups_scheduled_task[0].id
}

resource "aws_security_group_rule" "s3_azure_blob_storage_backups_scheduled_task_egress_dns_tcp" {
  count = local.enable_s3_backup_to_azure_blob_storage ? 1 : 0

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
  security_group_id = aws_security_group.s3_azure_blob_storage_backups_scheduled_task[0].id
}

resource "aws_security_group_rule" "s3_azure_blob_storage_backups_scheduled_task_egress_dns_udp" {
  count = local.enable_s3_backup_to_azure_blob_storage ? 1 : 0

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
  security_group_id = aws_security_group.s3_azure_blob_storage_backups_scheduled_task[0].id
}
