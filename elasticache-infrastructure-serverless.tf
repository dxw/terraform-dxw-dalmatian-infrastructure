resource "aws_elasticache_serverless_cache" "infrastructure_elasticache" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? {
    for k, v in local.infrastructure_elasticache : k => v if v["engine"] == "redis" && v["type"] == "serverless"
  } : {}

  engine = each.value["engine"]
  name   = "id-${local.resource_prefix_hash}-${substr(sha512(each.key), 0, 6)}"
  cache_usage_limits {
    data_storage {
      maximum = each.value["serverless_max_storage"]
      unit    = "GB"
    }
    ecpu_per_second {
      maximum = each.value["serverless_max_ecpu"]
    }
  }
  description              = "${local.resource_prefix} ${each.key}"
  kms_key_id               = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  major_engine_version     = each.value["engine_version"]
  snapshot_retention_limit = each.value["snapshot_retention_limit"] != null ? each.value["snapshot_retention_limit"] : 0
  security_group_ids       = [aws_security_group.infrastructure_elasticache[each.key].id]
  subnet_ids               = local.infrastructure_vpc_network_enable_private ? [for subnet in aws_subnet.infrastructure_private : subnet.id] : local.infrastructure_vpc_network_enable_public ? [for subnet in aws_subnet.infrastructure_public : subnet.id] : null

  tags = {
    Name = "${local.resource_prefix}-${each.key}"
  }
}
