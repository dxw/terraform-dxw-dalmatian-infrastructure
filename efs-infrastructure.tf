resource "aws_efs_file_system" "infrastructure_ecs_cluster" {
  count = local.enable_infrastructure_ecs_cluster_efs ? 1 : 0

  encrypted        = local.infrastructure_kms_encryption
  kms_key_id       = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  performance_mode = local.ecs_cluster_efs_performance_mode
  throughput_mode  = local.ecs_cluster_efs_throughput_mode

  dynamic "lifecycle_policy" {
    for_each = local.ecs_cluster_efs_infrequent_access_transition != 0 ? [1] : []
    content {
      transition_to_ia = "AFTER_${local.ecs_cluster_efs_infrequent_access_transition}_DAYS"
    }
  }

  dynamic "lifecycle_policy" {
    for_each = local.ecs_cluster_efs_infrequent_access_transition != 0 ? [1] : []
    content {
      transition_to_primary_storage_class = "AFTER_1_ACCESS"
    }
  }
}

resource "aws_efs_mount_target" "infrastructure_ecs_cluster" {
  for_each = local.enable_infrastructure_ecs_cluster_efs ? local.infrastructure_vpc_network_enable_private ? {
    for k, subnet in aws_subnet.infrastructure_private : k => subnet.id
    } : local.infrastructure_vpc_network_enable_public ? {
    for k, subnet in aws_subnet.infrastructure_public : k => subnet.id
  } : {} : {}

  file_system_id  = aws_efs_file_system.infrastructure_ecs_cluster[0].id
  subnet_id       = each.value
  security_groups = local.enable_infrastructure_ecs_cluster ? [aws_security_group.infrastructure_ecs_cluster_efs[0].id] : []
}

resource "aws_security_group" "infrastructure_ecs_cluster_efs" {
  count = local.enable_infrastructure_ecs_cluster_efs && local.enable_infrastructure_ecs_cluster ? 1 : 0

  name        = "${local.resource_prefix}-infrastructure-ecs-cluster-efs"
  description = "Infrastructure ECS cluster EFS"
  vpc_id      = aws_vpc.infrastructure[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_efs_ingress_nfs_tcp" {
  count = local.enable_infrastructure_ecs_cluster_efs && local.enable_infrastructure_ecs_cluster ? 1 : 0

  description              = "Allow ECS instances access to EFS (NFS) tcp"
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
  security_group_id        = aws_security_group.infrastructure_ecs_cluster_efs[0].id
}
