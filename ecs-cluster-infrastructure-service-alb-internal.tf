resource "aws_security_group" "infrastructure_ecs_cluster_service_internal_alb" {
  count = length(local.infrastructure_ecs_cluster_internal_services) > 0 ? 1 : 0

  name        = "${local.resource_prefix}-infrastructure-ecs-cluster-service-internal-alb"
  description = "Infrastructure ECS cluster service internal ALB"
  vpc_id      = aws_vpc.infrastructure[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_service_internal_alb_https" {
  count = length(local.infrastructure_ecs_cluster_internal_services) > 0 ? 1 : 0

  description              = "Allow port 443 (https) ingress from container instances"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
  security_group_id        = aws_security_group.infrastructure_ecs_cluster_service_internal_alb[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_service_internal_alb_container_instance_egress_tcp" {
  count = length(local.infrastructure_ecs_cluster_internal_services) > 0 ? 1 : 0

  description              = "Allow container port tcp egress to container instances"
  type                     = "egress"
  from_port                = 32768
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
  security_group_id        = aws_security_group.infrastructure_ecs_cluster_service_internal_alb[0].id
}

# Not gated on public subnets like the public ALB's ingress rules: the
# internal ALB does not depend on them.
resource "aws_security_group_rule" "infrastructure_ecs_cluster_container_instances_ingress_internal_alb_tcp" {
  count = length(local.infrastructure_ecs_cluster_internal_services) > 0 ? 1 : 0

  description              = "Allow container port tcp ingress from the internal ALB"
  type                     = "ingress"
  from_port                = 32768
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.infrastructure_ecs_cluster_service_internal_alb[0].id
  security_group_id        = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
}

resource "aws_alb" "infrastructure_ecs_cluster_service_internal" {
  count = length(local.infrastructure_ecs_cluster_internal_services) > 0 ? 1 : 0

  name = "${local.resource_prefix_hash}-${substr(sha512("infrastructure-ecs-cluster-service-internal"), 0, 6)}"

  load_balancer_type         = "application"
  internal                   = true
  drop_invalid_header_fields = true
  desync_mitigation_mode     = "defensive"
  preserve_host_header       = true
  xff_header_processing_mode = "append"

  subnets = [
    for subnet in aws_subnet.infrastructure_private : subnet.id
  ]

  security_groups = [
    aws_security_group.infrastructure_ecs_cluster_service_internal_alb[0].id,
  ]

  # Must stay above the longest request an internal service's callers allow.
  idle_timeout = 60

  dynamic "access_logs" {
    for_each = local.enable_infrastructure_ecs_cluster_services_alb_logs ? [1] : []

    content {
      bucket  = aws_s3_bucket.infrastructure_ecs_cluster_service_alb_logs[0].bucket
      enabled = true
    }
  }

  tags = {
    Name = "${local.resource_prefix}-infrastructure-ecs-cluster-service-internal"
  }

  lifecycle {
    precondition {
      condition     = local.enable_infrastructure_wildcard_certificate
      error_message = "internal services need the infrastructure Route53 hosted zone (enable_infrastructure_route53_hosted_zone), which provides their certificate and records."
    }

    precondition {
      condition     = local.infrastructure_vpc_network_enable_private
      error_message = "internal services need private subnets (infrastructure_vpc_network_enable_private)."
    }
  }

  depends_on = [
    aws_s3_bucket_policy.infrastructure_ecs_cluster_service_alb_logs
  ]
}

resource "aws_alb_listener" "infrastructure_ecs_cluster_service_internal_https" {
  count = length(local.infrastructure_ecs_cluster_internal_services) > 0 ? 1 : 0

  load_balancer_arn = aws_alb.infrastructure_ecs_cluster_service_internal[0].arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.infrastructure_wildcard[0].certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Misdirected Request"
      status_code  = "421"
    }
  }
}

resource "aws_alb_listener_rule" "infrastructure_ecs_cluster_service_internal_host_header" {
  for_each = local.infrastructure_ecs_cluster_internal_services

  listener_arn = aws_alb_listener.infrastructure_ecs_cluster_service_internal_https[0].arn

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.infrastructure_ecs_cluster_service[each.key].arn
  }

  condition {
    host_header {
      values = ["${each.key}.${local.infrastructure_route53_domain}"]
    }
  }

  lifecycle {
    ignore_changes = [
      action,
    ]
  }
}

resource "aws_route53_record" "service_record_internal" {
  for_each = local.infrastructure_ecs_cluster_internal_services

  zone_id = aws_route53_zone.infrastructure[0].zone_id
  name    = "${each.key}.${local.infrastructure_route53_domain}."
  type    = "A"

  alias {
    name                   = aws_alb.infrastructure_ecs_cluster_service_internal[0].dns_name
    zone_id                = aws_alb.infrastructure_ecs_cluster_service_internal[0].zone_id
    evaluate_target_health = true
  }
}
