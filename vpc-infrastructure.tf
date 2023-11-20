resource "aws_vpc" "infrastructure" {
  count = local.infrastructure_vpc ? 1 : 0

  cidr_block                           = local.infrastructure_vpc_cidr_block
  enable_dns_support                   = local.infrastructure_vpc_enable_dns_support
  enable_dns_hostnames                 = local.infrastructure_vpc_enable_dns_hostnames
  instance_tenancy                     = local.infrastructure_vpc_instance_tenancy
  enable_network_address_usage_metrics = local.infrastructure_vpc_enable_network_address_usage_metrics
  assign_generated_ipv6_cidr_block     = local.infrastructure_vpc_assign_generated_ipv6_cidr_block

  tags = {
    Name = "${local.resource_prefix}-infrastructure"
  }
}
