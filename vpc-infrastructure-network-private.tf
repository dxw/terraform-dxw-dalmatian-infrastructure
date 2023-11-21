resource "aws_route_table" "infrastructure_private" {
  count = local.infrastructure_vpc_network_enable_private ? 1 : 0

  vpc_id = aws_vpc.infrastructure[0].id

  tags = {
    Name = "${local.resource_prefix}-infrastructure-private"
  }
}

resource "aws_subnet" "infrastructure_private" {
  for_each = local.infrastructure_vpc_network_enable_private ? local.infrastructure_vpc_network_availability_zones : []

  vpc_id            = aws_vpc.infrastructure[0].id
  availability_zone = "${local.aws_region}${each.value}"

  cidr_block = cidrsubnet(
    local.infrastructure_vpc_network_private_cidr,
    local.infrastructure_vpc_network_private_cidr_newbits,
    index(tolist(local.infrastructure_vpc_network_availability_zones), each.value)
  )

  tags = {
    Name = "${local.resource_prefix}-infrastructure-private-${each.value}"
  }
}

resource "aws_route_table_association" "infrastructure_private" {
  for_each = local.infrastructure_vpc_network_enable_private ? local.infrastructure_vpc_network_availability_zones : []

  subnet_id      = aws_subnet.infrastructure_private[each.value].id
  route_table_id = aws_route_table.infrastructure_private[0].id
}

resource "aws_eip" "infrastructure_nat" {
  count = local.infrastructure_vpc_network_enable_private && local.infrastructure_vpc_network_enable_public ? 1 : 0

  domain = "vpc"

  tags = {
    Name = "${local.resource_prefix}-infrastructure-nat"
  }
}

resource "aws_nat_gateway" "infrastructure" {
  count = local.infrastructure_vpc_network_enable_private && local.infrastructure_vpc_network_enable_public ? 1 : 0

  allocation_id = aws_eip.infrastructure_nat[0].id
  subnet_id     = aws_subnet.infrastructure_public[element(tolist(local.infrastructure_vpc_network_availability_zones), 0)].id
  depends_on    = [aws_internet_gateway.infrastructure_public]
}

resource "aws_route" "private_nat_gateway" {
  count = local.infrastructure_vpc_network_enable_private && local.infrastructure_vpc_network_enable_public ? 1 : 0

  route_table_id         = aws_route_table.infrastructure_private[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.infrastructure[0].id
}
