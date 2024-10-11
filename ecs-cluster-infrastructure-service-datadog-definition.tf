resource "datadog_service_definition_yaml" "infrastructure_ecs_cluster_service" {
  for_each = local.enable_infrastructure_ecs_cluster_datadog_agent ? local.infrastructure_ecs_cluster_services : {}

  service_definition = yamlencode({
    schema-version = "v2.2",
    dd-service     = aws_ecs_task_definition.infrastructure_ecs_cluster_service[each.key].family
    team           = ""
    links = [
      {
        name     = "Home"
        type     = "other"
        provider = "URL"
        url      = each.value["domain_names"] != null ? join(",", [for domain in each.value["domain_names"] : "https://${domain}"]) : "https://${each.key}.${local.infrastructure_route53_domain}"
      }
    ]
  })
}
