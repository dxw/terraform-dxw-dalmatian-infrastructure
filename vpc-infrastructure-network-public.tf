resource "aws_route_table" "infrastructure_public" {
  count = local.infrastructure_vpc_network_enable_public ? 1 : 0

  vpc_id = aws_vpc.infrastructure[0].id

  tags = {
    Name = "${local.resource_prefix}-infrastructure-public"
  }
}

resource "aws_internet_gateway" "infrastructure_public" {
  count = local.infrastructure_vpc_network_enable_public ? 1 : 0

  vpc_id = aws_vpc.infrastructure[0].id

  tags = {
    Name = "${local.resource_prefix}-infrastructure-public"
  }
}

resource "aws_route" "infrustructure_public_internet_gateway" {
  count = local.infrastructure_vpc_network_enable_public ? 1 : 0

  route_table_id         = aws_route_table.infrastructure_public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.infrastructure_public[0].id
}

resource "aws_subnet" "infrastructure_public" {
  for_each = local.infrastructure_vpc_network_enable_public ? local.infrastructure_vpc_network_availability_zones : []

  vpc_id            = aws_vpc.infrastructure[0].id
  availability_zone = "${local.aws_region}${each.value}"

  cidr_block = cidrsubnet(
    local.infrastructure_vpc_network_public_cidr,
    local.infrastructure_vpc_network_public_cidr_newbits,
    index(tolist(local.infrastructure_vpc_network_availability_zones), each.value)
  )

  tags = {
    Name = "${local.resource_prefix}-infrastructure-public-${each.value}"
  }
}

resource "aws_route_table_association" "infrastructure_public" {
  for_each = local.infrastructure_vpc_network_enable_public ? local.infrastructure_vpc_network_availability_zones : []

  subnet_id      = aws_subnet.infrastructure_public[each.value].id
  route_table_id = aws_route_table.infrastructure_public[0].id
}
