resource "aws_db_subnet_group" "infrastructure_rds" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? local.infrastructure_rds : {}

  name        = "${local.resource_prefix}-${each.key}"
  description = "Subnet Group for ${local.resource_prefix}-${each.key} RDS"
  subnet_ids  = local.infrastructure_vpc_network_enable_private ? [for subnet in aws_subnet.infrastructure_private : subnet.id] : local.infrastructure_vpc_network_enable_public ? [for subnet in aws_subnet.infrastructure_public : subnet.id] : null
}
