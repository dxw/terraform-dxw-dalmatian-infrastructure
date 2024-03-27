resource "aws_security_group" "custom_lambda" {
  for_each = local.infrastructure_vpc_network_enable_public || local.infrastructure_vpc_network_enable_private ? {
    for k, custom_lambda in local.custom_lambda_functions : k => custom_lambda if custom_lambda["launch_in_infrastructure_vpc"] == true
  } : {}

  name        = "${local.resource_prefix}-custom-lambda-${each.key}"
  description = "${local.resource_prefix} custom lambda ${each.key}"
  vpc_id      = aws_vpc.infrastructure[0].id
}
