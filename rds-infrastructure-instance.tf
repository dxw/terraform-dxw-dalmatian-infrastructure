resource "aws_db_parameter_group" "infrastructure_rds" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? {
    for k, v in local.infrastructure_rds : k => v if v["type"] == "instance"
  } : {}

  name        = "${local.resource_prefix}-${each.key}-${each.value["engine"]}-${replace(each.value["engine_version"], ".", "-")}"
  description = "Parameter Group for ${local.resource_prefix}-${each.key} RDS"
  family      = local.rds_engines[each.value["type"]][each.value["engine"]] == "mysql" ? "mysql${join(".", slice(split(".", each.value["engine_version"]), 0, 2))}" : local.rds_engines[each.value["type"]][each.value["engine"]] == "postgres" ? "postgres${split(".", each.value["engine_version"])[0]}" : null

  dynamic "parameter" {
    for_each = each.value["parameters"] != null ? each.value["parameters"] : {}

    content {
      name  = each.key
      value = each.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_option_group" "infrastructure_rds" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? {
    for k, v in local.infrastructure_rds : k => v if v["type"] == "instance"
  } : {}

  name                     = "${local.resource_prefix}-${each.key}-${each.value["engine"]}-${replace(each.value["engine_version"], ".", "-")}"
  option_group_description = "Option group for ${local.resource_prefix}-${each.key} RDS"
  engine_name              = local.rds_engines[each.value["type"]][each.value["engine"]]
  major_engine_version     = local.rds_engines[each.value["type"]][each.value["engine"]] == "mysql" ? join(".", slice(split(".", each.value["engine_version"]), 0, 2)) : local.rds_engines[each.value["type"]][each.value["engine"]] == "postgres" ? split(".", each.value["engine_version"])[0] : null

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "infrastructure_rds" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? {
    for k, v in local.infrastructure_rds : k => v if v["type"] == "instance"
  } : {}

  identifier                    = "${length(regexall("^[0-9]", substr(local.resource_prefix_hash, 0, 1))) > 0 ? "h" : ""}${local.resource_prefix_hash}-${each.key}"
  engine                        = local.rds_engines[each.value["type"]][each.value["engine"]]
  engine_version                = each.value["engine_version"]
  allow_major_version_upgrade   = false
  auto_minor_version_upgrade    = true
  apply_immediately             = true
  maintenance_window            = "Mon:19:00-Mon:22:00"
  instance_class                = each.value["instance_class"]
  kms_key_id                    = each.value["dedicated_kms_key"] == true ? aws_kms_key.infrastructure_rds[each.key].arn : local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  license_model                 = local.rds_licenses[each.value["engine"]]
  db_name                       = null
  username                      = "root"
  manage_master_user_password   = true
  master_user_secret_kms_key_id = v["dedicated_kms_key"] == true ? aws_kms_key.infrastructure_rds[each.key].key_id : null
  character_set_name            = null
  timezone                      = null
  deletion_protection           = false
  delete_automated_backups      = true

  backup_window             = "22:00-23:59"
  copy_tags_to_snapshot     = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${length(regexall("^[0-9]", substr(local.resource_prefix_hash, 0, 1))) > 0 ? "h" : ""}${local.resource_prefix_hash}-${each.key}-final"
  backup_retention_period   = 35

  monitoring_interval                   = each.value["monitoring_interval"]
  monitoring_role_arn                   = each.value["monitoring_interval"] != null && each.value["monitoring_interval"] != 0 ? aws_iam_role.infrastructure_rds_monitoring[each.key].arn : null
  performance_insights_enabled          = !contains(["small", "micro"], split(".", each.value["instance_class"])[2]) ? true : null
  performance_insights_kms_key_id       = !contains(["small", "micro"], split(".", each.value["instance_class"])[2]) && local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  performance_insights_retention_period = !contains(["small", "micro"], split(".", each.value["instance_class"])[2]) ? 31 : null
  enabled_cloudwatch_logs_exports       = each.value["cloudwatch_logs_export_types"]

  allocated_storage   = each.value["allocated_storage"]
  storage_type        = each.value["storage_type"]
  storage_encrypted   = true
  iops                = each.value["iops"]
  storage_throughput  = each.value["storage_throughput"]
  publicly_accessible = false
  ca_cert_identifier  = "rds-ca-rsa4096-g1"

  vpc_security_group_ids = [aws_security_group.infrastructure_rds[each.key].id]
  db_subnet_group_name   = aws_db_subnet_group.infrastructure_rds[each.key].name
  parameter_group_name   = aws_db_parameter_group.infrastructure_rds[each.key].name
  option_group_name      = aws_db_option_group.infrastructure_rds[each.key].name
  network_type           = "IPV4"
  port                   = local.rds_ports[each.value["engine"]]
  availability_zone      = "${local.aws_region}${sort(tolist(local.infrastructure_vpc_network_availability_zones))[0]}"
  multi_az               = each.value["multi_az"]

  depends_on = [
    aws_cloudwatch_log_group.infrastructure_rds_exports,
    aws_iam_role_policy_attachment.infrastructure_rds_monitoring,
  ]
}
