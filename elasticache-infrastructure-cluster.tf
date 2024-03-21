resource "aws_elasticache_parameter_group" "infrastructure_elasticache_cluster" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? {
    for k, v in local.infrastructure_elasticache : k => merge(v, {
      parameter_group_version = replace(v["engine_version"], "6.", "") != v["engine_version"] ? "6.x" : (
        replace(v["engine_version"], "7.", "") != v["engine_version"] ? "7" : replace(v["engine_version"], "/\\.[\\d]+$/", "")
      )
    }) if v["engine"] == "redis" && v["type"] == "cluster"
  } : {}

  name = "pg-${local.resource_prefix_hash}-${each.key}-${replace(each.value["parameter_group_version"], ".", "-")}"

  description = "Parameter Group for ${local.resource_prefix_hash} ${each.key} ${each.value["parameter_group_version"]}"

  family = "${each.value["engine"]}${each.value["parameter_group_version"]}"

  dynamic "parameter" {
    for_each = each.value["parameters"] != null ? each.value["parameters"] : {}
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elasticache_subnet_group" "infrastructure_elasticache_cluster_subnet_group" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? {
    for k, v in local.infrastructure_elasticache : k => v if v["engine"] == "redis" && v["type"] == "cluster"
  } : {}

  name       = "id-${local.resource_prefix_hash}-${substr(sha512(each.key), 0, 6)}"
  subnet_ids = local.infrastructure_vpc_network_enable_private ? [for subnet in aws_subnet.infrastructure_private : subnet.id] : local.infrastructure_vpc_network_enable_public ? [for subnet in aws_subnet.infrastructure_public : subnet.id] : null
}

resource "aws_elasticache_replication_group" "infrastructure_elasticache_cluster" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? {
    for k, v in local.infrastructure_elasticache : k => v if v["engine"] == "redis" && v["type"] == "cluster"
  } : {}

  replication_group_id = "id-${local.resource_prefix_hash}-${substr(sha512(each.key), 0, 6)}"
  description          = "ElastiCache replication group for ${local.resource_prefix} ${each.key}"

  node_type                  = each.value["cluster_node_type"]
  num_cache_clusters         = each.value["cluster_node_count"]
  engine_version             = each.value["engine_version"]
  port                       = local.elasticache_ports[each.value["engine"]]
  at_rest_encryption_enabled = true

  parameter_group_name = aws_elasticache_parameter_group.infrastructure_elasticache_cluster[each.key].id
  subnet_group_name    = aws_elasticache_subnet_group.infrastructure_elasticache_cluster_subnet_group[each.key].id
  security_group_ids   = [aws_security_group.infrastructure_elasticache[each.key].id]

  maintenance_window       = "Mon:19:00-Mon:22:00"
  snapshot_window          = "22:00-23:59"
  snapshot_retention_limit = each.value["snapshot_retention_limit"] != null ? each.value["snapshot_retention_limit"] : 0

  automatic_failover_enabled = false
  apply_immediately          = true

  tags = {
    Name = "${local.resource_prefix}-${each.key}"
  }
}
