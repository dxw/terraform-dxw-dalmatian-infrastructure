resource "aws_cloudfront_monitoring_subscription" "infrastructure_ecs_cluster_service" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["enable_cloudfront"] == true && v["cloudfront_enhanced_metrics_enabled"] == true
  }

  distribution_id = aws_cloudfront_distribution.infrastructure_ecs_cluster_service_cloudfront[each.key].id

  monitoring_subscription {
    realtime_metrics_subscription_config {
      realtime_metrics_subscription_status = "Enabled"
    }
  }
}
