resource "aws_acm_certificate" "infrastructure_wildcard" {
  count = local.enable_infrastructure_wildcard_certificate ? 1 : 0

  domain_name       = "*.${local.infrastructure_route53_domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "infrastructure_wildcard" {
  count = local.enable_infrastructure_wildcard_certificate ? 1 : 0

  certificate_arn         = aws_acm_certificate.infrastructure_wildcard[0].arn
  validation_record_fqdns = [for record in aws_route53_record.infrastructure_wildcard_ssl_verification : record.fqdn]
}


resource "aws_acm_certificate" "infrastructure_wildcard_us_east_1" {
  count = local.enable_infrastructure_wildcard_certificate && (contains([for service in local.infrastructure_ecs_cluster_services : service["enable_cloudfront"]], true) || length(local.custom_s3_buckets) > 0) ? 1 : 0

  provider = aws.useast1

  domain_name       = "*.${local.infrastructure_route53_domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "infrastructure_wildcard_us_east_1" {
  count = local.enable_infrastructure_wildcard_certificate && (contains([for service in local.infrastructure_ecs_cluster_services : service["enable_cloudfront"]], true) || length(local.custom_s3_buckets) > 0) ? 1 : 0

  provider = aws.useast1

  certificate_arn         = aws_acm_certificate.infrastructure_wildcard_us_east_1[0].arn
  validation_record_fqdns = [for record in aws_route53_record.infrastructure_wildcard_ssl_verification : record.fqdn]
}
