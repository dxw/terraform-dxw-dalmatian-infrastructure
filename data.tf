data "aws_caller_identity" "current" {}

data "aws_route53_zone" "root" {
  count = local.create_infrastructure_route53_delegations ? 1 : 0

  name = local.route53_root_hosted_zone_domain_name
}

data "aws_ami" "ecs_cluster_ami" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"
    values = [
      "amzn2-ami-ecs-hvm-${local.infrastructure_ecs_cluster_ami_version}"
    ]
  }

  filter {
    name = "architecture"
    values = [
      "x86_64"
    ]
  }
}
