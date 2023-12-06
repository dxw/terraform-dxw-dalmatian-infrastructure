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
