#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "infrastructure_ecs_cluster_datadog_agent_api_key" {
  count = local.enable_infrastructure_ecs_cluster_datadog_agent ? 1 : 0

  name = "${local.resource_prefix_hash}/ecs/datadog-agent/DD_API_KEY"
}

resource "aws_secretsmanager_secret_version" "infrastructure_ecs_cluster_datadog_agent_api_key" {
  count = local.enable_infrastructure_ecs_cluster_datadog_agent ? 1 : 0

  secret_id     = aws_secretsmanager_secret.infrastructure_ecs_cluster_datadog_agent_api_key[0].id
  secret_string = local.infrastructure_datadog_api_key
}
