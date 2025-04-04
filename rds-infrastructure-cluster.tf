resource "aws_rds_cluster" "infrastructure_rds" {
  for_each = {
    for k, v in local.infrastructure_rds : k => v if v["type"] == "cluster"
  }

  cluster_identifier                  = "${length(regexall("^[0-9]", substr(local.resource_prefix_hash, 0, 1))) > 0 ? "h" : ""}${local.resource_prefix_hash}-${each.key}"
  engine                              = local.rds_engines[each.value["type"]][each.value["engine"]]
  engine_version                      = each.value["engine_version"]
  engine_mode                         = "provisioned"
  db_cluster_instance_class           = null
  db_cluster_parameter_group_name     = null
  db_instance_parameter_group_name    = null
  cluster_members                     = null
  allow_major_version_upgrade         = false
  apply_immediately                   = true
  preferred_maintenance_window        = "mon:19:00-mon:22:00"
  master_username                     = "root"
  manage_master_user_password         = true
  master_user_secret_kms_key_id       = each.value["dedicated_kms_key"] == true ? aws_kms_key.infrastructure_rds[each.key].key_id : null
  iam_database_authentication_enabled = null
  deletion_protection                 = false
  enable_http_endpoint                = false

  enabled_cloudwatch_logs_exports = each.value["cloudwatch_logs_export_types"]

  preferred_backup_window   = "22:00-23:59"
  backtrack_window          = 0
  copy_tags_to_snapshot     = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${length(regexall("^[0-9]", substr(local.resource_prefix_hash, 0, 1))) > 0 ? "h" : ""}${local.resource_prefix_hash}-${each.key}-final"
  backup_retention_period   = 30

  allocated_storage              = null
  storage_type                   = each.value["storage_type"]
  storage_encrypted              = true
  iops                           = each.value["iops"]
  kms_key_id                     = each.value["dedicated_kms_key"] == true ? aws_kms_key.infrastructure_rds[each.key].arn : local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  enable_global_write_forwarding = null

  db_subnet_group_name   = aws_db_subnet_group.infrastructure_rds[each.key].name
  availability_zones     = [for az in local.infrastructure_vpc_network_availability_zones : "${local.aws_region}${az}"]
  network_type           = "IPV4"
  port                   = local.rds_ports[each.value["engine"]]
  vpc_security_group_ids = [aws_security_group.infrastructure_rds[each.key].id]

  serverlessv2_scaling_configuration {
    min_capacity = each.value["cluster_serverlessv2_min_capacity"]
    max_capacity = each.value["cluster_serverlessv2_max_capacity"]
  }

  depends_on = [
    aws_cloudwatch_log_group.infrastructure_rds_exports,
  ]
}

resource "aws_rds_cluster_instance" "infrastructure_rds" {
  for_each = merge(flatten([for k, v in local.infrastructure_rds :
    flatten([
      for instance_num in range(0, v["cluster_instance_count"]) : { "${k}-${instance_num}" = merge(v, { cluster_instance_num = instance_num, cluster_key = k }) }
    ])
    if v["type"] == "cluster"
  ])...)

  identifier                 = "${length(regexall("^[0-9]", substr(local.resource_prefix_hash, 0, 1))) > 0 ? "h" : ""}${local.resource_prefix_hash}-${each.key}-${each.value["cluster_instance_num"]}"
  cluster_identifier         = aws_rds_cluster.infrastructure_rds[each.value["cluster_key"]].id
  engine                     = local.rds_engines[each.value["type"]][each.value["engine"]]
  engine_version             = each.value["engine_version"]
  apply_immediately          = true
  auto_minor_version_upgrade = true
  instance_class             = "db.serverless"
  promotion_tier             = null

  monitoring_interval                   = each.value["monitoring_interval"]
  monitoring_role_arn                   = each.value["monitoring_interval"] != null && each.value["monitoring_interval"] != 0 ? aws_iam_role.infrastructure_rds_monitoring[each.value["cluster_key"]].arn : null
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  performance_insights_retention_period = 31
  copy_tags_to_snapshot                 = true

  ca_cert_identifier = "rds-ca-rsa4096-g1"

  db_subnet_group_name = aws_db_subnet_group.infrastructure_rds[each.value["cluster_key"]].name
  availability_zone    = "${local.aws_region}${sort(tolist(local.infrastructure_vpc_network_availability_zones))[each.value["cluster_instance_num"] % length(local.infrastructure_vpc_network_availability_zones)]}"
  publicly_accessible  = false
}
