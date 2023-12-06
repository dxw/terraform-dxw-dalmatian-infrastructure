data "aws_caller_identity" "current" {}

data "aws_route53_zone" "root" {
  count = local.create_infrastructure_route53_delegations ? 1 : 0

  name = local.route53_root_hosted_zone_domain_name
}
