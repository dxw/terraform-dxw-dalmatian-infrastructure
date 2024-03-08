resource "aws_globalaccelerator_accelerator" "infrastructure_ecs_cluster_service_alb" {
  count = local.infrastructure_ecs_cluster_services_alb_enable_global_accelerator ? 1 : 0

  name            = "${local.resource_prefix_hash}-infrastructure-ecs-cluster-service-alb"
  ip_address_type = "DUAL_STACK"
  enabled         = true
}

resource "aws_globalaccelerator_listener" "infrastructure_ecs_cluster_service_alb_http" {
  count = local.infrastructure_ecs_cluster_services_alb_enable_global_accelerator ? 1 : 0

  accelerator_arn = aws_globalaccelerator_accelerator.infrastructure_ecs_cluster_service_alb[0].id
  client_affinity = "SOURCE_IP"
  protocol        = "TCP"

  port_range {
    from_port = 80
    to_port   = 80
  }
}

resource "aws_globalaccelerator_listener" "infrastructure_ecs_cluster_service_alb_https" {
  count = local.infrastructure_ecs_cluster_services_alb_enable_global_accelerator && local.enable_infrastructure_wildcard_certificate ? 1 : 0

  accelerator_arn = aws_globalaccelerator_accelerator.infrastructure_ecs_cluster_service_alb[0].id
  client_affinity = "SOURCE_IP"
  protocol        = "TCP"

  port_range {
    from_port = 443
    to_port   = 443
  }
}

resource "aws_globalaccelerator_endpoint_group" "service_loadbalancer_alb_http" {
  count = local.infrastructure_ecs_cluster_services_alb_enable_global_accelerator ? 1 : 0

  listener_arn                  = aws_globalaccelerator_listener.infrastructure_ecs_cluster_service_alb_http[0].id
  endpoint_group_region         = local.aws_region
  health_check_interval_seconds = 30
  health_check_protocol         = "TCP"
  threshold_count               = 3
  traffic_dial_percentage       = 100

  endpoint_configuration {
    client_ip_preservation_enabled = false
    endpoint_id                    = aws_alb.infrastructure_ecs_cluster_service[0].arn
    weight                         = 100
  }
}

resource "aws_globalaccelerator_endpoint_group" "service_loadbalancer_alb_https" {
  count = local.infrastructure_ecs_cluster_services_alb_enable_global_accelerator && local.enable_infrastructure_wildcard_certificate ? 1 : 0

  listener_arn                  = aws_globalaccelerator_listener.infrastructure_ecs_cluster_service_alb_https[0].id
  endpoint_group_region         = local.aws_region
  health_check_interval_seconds = 30
  health_check_protocol         = "TCP"
  threshold_count               = 3
  traffic_dial_percentage       = 100

  endpoint_configuration {
    client_ip_preservation_enabled = false
    endpoint_id                    = aws_alb.infrastructure_ecs_cluster_service[0].arn
    weight                         = 100
  }
}
