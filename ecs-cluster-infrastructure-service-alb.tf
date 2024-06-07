resource "aws_security_group" "infrastructure_ecs_cluster_service_alb" {
  count = length(local.infrastructure_ecs_cluster_services) > 0 ? 1 : 0

  name        = "${local.resource_prefix}-infrastructure-ecs-cluster-service-alb"
  description = "Infrastructure ECS cluster service ALB"
  vpc_id      = aws_vpc.infrastructure[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_service_alb_container_instance_egress_tcp" {
  count = length(local.infrastructure_ecs_cluster_services) > 0 ? 1 : 0

  description              = "Allow container port tcp egress to container instances"
  type                     = "egress"
  from_port                = 32768
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
  security_group_id        = aws_security_group.infrastructure_ecs_cluster_service_alb[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_service_alb_container_instance_egress_udp" {
  count = length(local.infrastructure_ecs_cluster_services) > 0 ? 1 : 0

  description              = "Allow container port udp egress to container instances"
  type                     = "egress"
  from_port                = 32768
  to_port                  = 65535
  protocol                 = "udp"
  source_security_group_id = aws_security_group.infrastructure_ecs_cluster_container_instances[0].id
  security_group_id        = aws_security_group.infrastructure_ecs_cluster_service_alb[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_service_alb_http" {
  count = length(local.infrastructure_ecs_cluster_services) > 0 ? 1 : 0

  description       = "Allow port 80 (http) ingress for the service ALB"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = local.infrastructure_ecs_cluster_services_alb_ip_allow_list
  security_group_id = aws_security_group.infrastructure_ecs_cluster_service_alb[0].id
}

resource "aws_security_group_rule" "infrastructure_ecs_cluster_service_alb_https" {
  count = length(local.infrastructure_ecs_cluster_services) > 0 ? 1 : 0

  description       = "Allow port 443 (https) ingress for the service ALB"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = local.infrastructure_ecs_cluster_services_alb_ip_allow_list
  security_group_id = aws_security_group.infrastructure_ecs_cluster_service_alb[0].id
}

#tfsec:ignore:aws-elb-alb-not-public
resource "aws_alb" "infrastructure_ecs_cluster_service" {
  count = length(local.infrastructure_ecs_cluster_services) > 0 ? 1 : 0

  name = "${local.resource_prefix_hash}-${substr(sha512("infrastructure-ecs-cluster-service"), 0, 6)}"

  load_balancer_type         = "application"
  internal                   = false
  drop_invalid_header_fields = true
  desync_mitigation_mode     = "defensive"
  preserve_host_header       = true
  xff_header_processing_mode = "append"

  subnets = local.infrastructure_vpc_network_enable_public ? [
    for subnet in aws_subnet.infrastructure_public : subnet.id
  ] : []

  security_groups = [
    aws_security_group.infrastructure_ecs_cluster_service_alb[0].id,
  ]

  idle_timeout = 60

  dynamic "access_logs" {
    for_each = local.enable_infrastructure_ecs_cluster_services_alb_logs ? [1] : []

    content {
      bucket  = aws_s3_bucket.infrastructure_ecs_cluster_service_alb_logs[0].bucket
      enabled = true
    }
  }

  tags = {
    Name = "${local.resource_prefix}-infrastructure-ecs-cluster-service"
  }

  depends_on = [
    aws_s3_bucket_policy.infrastructure_ecs_cluster_service_alb_logs
  ]
}

resource "aws_alb_listener" "infrastructure_ecs_cluster_service_http_https_redirect" {
  count = length(local.infrastructure_ecs_cluster_services) > 0 && local.enable_infrastructure_wildcard_certificate ? 1 : 0

  load_balancer_arn = aws_alb.infrastructure_ecs_cluster_service[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

#tfsec:ignore:aws-elb-http-not-used
resource "aws_alb_listener" "infrastructure_ecs_cluster_service_http" {
  count = length(local.infrastructure_ecs_cluster_services) > 0 && !local.enable_infrastructure_wildcard_certificate ? 1 : 0

  load_balancer_arn = aws_alb.infrastructure_ecs_cluster_service[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Misdirected Request"
      status_code  = "421"
    }
  }
}

resource "aws_alb_listener" "infrastructure_ecs_cluster_service_https" {
  count = length(local.infrastructure_ecs_cluster_services) > 0 && local.enable_infrastructure_wildcard_certificate ? 1 : 0

  load_balancer_arn = aws_alb.infrastructure_ecs_cluster_service[0].arn
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

resource "aws_alb_listener_rule" "infrastructure_ecs_cluster_service_host_header" {
  for_each = {
    for k, service in local.infrastructure_ecs_cluster_services : k => service if service["domain_names"] == null && service["container_port"] != 0
  }

  listener_arn = local.enable_infrastructure_wildcard_certificate ? aws_alb_listener.infrastructure_ecs_cluster_service_https[0].arn : aws_alb_listener.infrastructure_ecs_cluster_service_http[0].arn

  action {
    type             = "forward"
    target_group_arn = each.value["deployment_type"] == "rolling" ? aws_alb_target_group.infrastructure_ecs_cluster_service[each.key].arn : each.value["deployment_type"] == "blue-green" ? aws_alb_target_group.infrastructure_ecs_cluster_service_blue[each.key].arn : null
  }

  dynamic "condition" {
    for_each = each.value["enable_cloudfront"] == true && each.value["cloudfront_bypass_protection_enabled"] == true ? [1] : []

    content {
      http_header {
        http_header_name = "X-CloudFront-Secret"
        values           = [random_password.infrastructure_ecs_cluster_service_cloudfront_bypass_protection_secret[each.key].result]
      }
    }
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

resource "aws_alb_listener_rule" "infrastructure_ecs_cluster_service_host_header_custom" {
  for_each = {
    for k, service in local.infrastructure_ecs_cluster_services : k => service if service["domain_names"] != null && service["container_port"] != 0
  }

  listener_arn = each.value["alb_tls_certificate_arn"] != null ? aws_alb_listener.infrastructure_ecs_cluster_service_https[0].arn : aws_alb_listener.infrastructure_ecs_cluster_service_http[0].arn

  action {
    type             = "forward"
    target_group_arn = each.value["deployment_type"] == "rolling" ? aws_alb_target_group.infrastructure_ecs_cluster_service[each.key].arn : each.value["deployment_type"] == "blue-green" ? aws_alb_target_group.infrastructure_ecs_cluster_service_blue[each.key].arn : null
  }

  dynamic "condition" {
    for_each = each.value["enable_cloudfront"] == true && each.value["cloudfront_bypass_protection_enabled"] == true ? [1] : []

    content {
      http_header {
        http_header_name = "X-CloudFront-Secret"
        values           = [random_password.infrastructure_ecs_cluster_service_cloudfront_bypass_protection_secret[each.key].result]
      }
    }
  }

  condition {
    host_header {
      values = each.value["domain_names"]
    }
  }

  lifecycle {
    ignore_changes = [
      action,
    ]
  }
}

resource "aws_lb_listener_certificate" "service_shared_alb_certificate" {
  for_each = {
    for k, service in local.infrastructure_ecs_cluster_services : k => service if service["domain_names"] != null && service["container_port"] != 0 && service["alb_tls_certificate_arn"] != null
  }

  listener_arn    = aws_alb_listener.infrastructure_ecs_cluster_service_https[0].arn
  certificate_arn = each.value["alb_tls_certificate_arn"]
}

resource "aws_alb_listener_rule" "service_alb_host_rule_bypass_exclusions" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if(
      v["enable_cloudfront"] == true &&
      v["cloudfront_bypass_protection_enabled"] == true &&
      v["cloudfront_bypass_protection_excluded_domains"] != null &&
      v["container_port"] != 0
    )
  }

  listener_arn = local.enable_infrastructure_wildcard_certificate || each.value["alb_tls_certificate_arn"] != null ? aws_alb_listener.infrastructure_ecs_cluster_service_https[0].arn : aws_alb_listener.infrastructure_ecs_cluster_service_http[0].arn

  action {
    type             = "forward"
    target_group_arn = each.value["deployment_type"] == "rolling" ? aws_alb_target_group.infrastructure_ecs_cluster_service[each.key].arn : each.value["deployment_type"] == "blue-green" ? aws_alb_target_group.infrastructure_ecs_cluster_service_blue[each.key].arn : null
  }

  condition {
    host_header {
      values = each.value["cloudfront_bypass_protection_excluded_domains"]
    }
  }

  lifecycle {
    ignore_changes = [
      action,
    ]
  }
}
