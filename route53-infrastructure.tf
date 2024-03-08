resource "aws_route53_zone" "infrastructure" {
  count = local.enable_infrastructure_route53_hosted_zone ? 1 : 0

  name = local.infrastructure_route53_domain
}

resource "aws_route53_record" "infrastructure_ns" {
  count = local.create_infrastructure_route53_delegations ? 1 : 0

  provider = aws.awsroute53root

  name    = local.infrastructure_route53_domain
  ttl     = 172800
  type    = "NS"
  zone_id = data.aws_route53_zone.root[0].zone_id

  records = [
    aws_route53_zone.infrastructure[0].name_servers[0],
    aws_route53_zone.infrastructure[0].name_servers[1],
    aws_route53_zone.infrastructure[0].name_servers[2],
    aws_route53_zone.infrastructure[0].name_servers[3],
  ]
}

resource "aws_route53_record" "infrastructure_wildcard_ssl_verification" {
  for_each = local.enable_infrastructure_wildcard_certificate ? {
    for dvo in aws_acm_certificate.infrastructure_wildcard[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.infrastructure[0].zone_id
}

resource "aws_route53_record" "service_loadbalancer_record_alb" {
  count = length(local.infrastructure_ecs_cluster_services) > 0 && local.enable_infrastructure_route53_hosted_zone ? 1 : 0

  zone_id = aws_route53_zone.infrastructure[0].zone_id
  name    = "alb.${local.infrastructure_route53_domain}."
  type    = "A"

  alias {
    name                   = aws_alb.infrastructure_ecs_cluster_service[0].dns_name
    zone_id                = aws_alb.infrastructure_ecs_cluster_service[0].zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "service_loadbalancer_record_alb_global_accelerator_a" {
  count = local.infrastructure_ecs_cluster_services_alb_enable_global_accelerator && local.enable_infrastructure_route53_hosted_zone ? 1 : 0

  zone_id = aws_route53_zone.infrastructure[0].zone_id
  name    = "ga.${local.infrastructure_route53_domain}."
  type    = "A"

  alias {
    name                   = aws_globalaccelerator_accelerator.infrastructure_ecs_cluster_service_alb[0].dns_name
    zone_id                = aws_globalaccelerator_accelerator.infrastructure_ecs_cluster_service_alb[0].hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "service_record" {
  for_each = local.enable_infrastructure_route53_hosted_zone ? local.infrastructure_ecs_cluster_services : {}

  zone_id = aws_route53_zone.infrastructure[0].zone_id
  name    = "${each.key}.${local.infrastructure_route53_domain}."
  type    = "A"

  alias {
    name                   = each.value["enable_cloudfront"] == true ? aws_cloudfront_distribution.infrastructure_ecs_cluster_service_cloudfront[each.key].domain_name : aws_alb.infrastructure_ecs_cluster_service[0].dns_name
    zone_id                = each.value["enable_cloudfront"] == true ? aws_cloudfront_distribution.infrastructure_ecs_cluster_service_cloudfront[each.key].hosted_zone_id : aws_alb.infrastructure_ecs_cluster_service[0].zone_id
    evaluate_target_health = true
  }
}
