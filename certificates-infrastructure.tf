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
