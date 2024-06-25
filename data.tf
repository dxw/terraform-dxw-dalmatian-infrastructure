data "aws_caller_identity" "current" {}

data "aws_elb_service_account" "current" {}

data "aws_route53_zone" "root" {
  count = local.create_infrastructure_route53_delegations ? 1 : 0

  provider = aws.awsroute53root

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

data "aws_sns_topic" "infrastructure_slack_sns_topic" {
  count = local.infrastructure_slack_sns_topic_in_use ? 1 : 0

  name = local.infrastructure_slack_sns_topic_name
}

data "aws_sns_topic" "infrastructure_opsgenie_sns_topic" {
  count = local.infrastructure_opsgenie_sns_topic_in_use ? 1 : 0

  name = local.infrastructure_opsgenie_sns_topic_name
}

data "aws_s3_object" "ecs_cluster_service_buildspec" {
  for_each = {
    for k, service in local.infrastructure_ecs_cluster_services : k => service if service["buildspec_from_github_repo"] == null || service["buildspec_from_github_repo"] == false
  }

  bucket = aws_s3_bucket.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store[0].id
  key    = each.value["buildspec"] != null ? each.value["buildspec"] : "dalmatian-default.yml"

  depends_on = [
    aws_s3_object.infrastructure_ecs_cluster_service_build_pipeline_buildspec_store_files,
  ]
}

data "aws_cloudfront_cache_policy" "managed_policy" {
  for_each = toset([
    for service in local.infrastructure_ecs_cluster_services : service["cloudfront_managed_cache_policy"] if service["cloudfront_managed_cache_policy"] != null
  ])

  name = "Managed-${each.value}"
}

data "aws_cloudfront_origin_request_policy" "managed_policy" {
  for_each = toset([
    for service in local.infrastructure_ecs_cluster_services : service["cloudfront_managed_origin_request_policy"] if service["cloudfront_managed_origin_request_policy"] != null
  ])

  name = "Managed-${each.value}"
}

data "aws_cloudfront_response_headers_policy" "managed_policy" {
  for_each = toset([
    for service in local.infrastructure_ecs_cluster_services : service["cloudfront_managed_response_headers_policy"] if service["cloudfront_managed_response_headers_policy"] != null
  ])

  name = "Managed-${each.value}"
}

# aws_ssm_service_setting doesn't yet have a data source, so we need to use
# a script to retrieve SSM service settings
# https://github.com/hashicorp/terraform-provider-aws/issues/25170
data "external" "ssm_dhmc_setting" {
  count = local.enable_infrastructure_ecs_cluster ? 1 : 0

  program = ["/bin/bash", "external-data-scripts/get-ssm-service-setting.sh"]

  query = {
    setting_id = "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:servicesetting/ssm/managed-instance/default-ec2-instance-management-role"
  }
}

data "external" "s3_presigned_url" {
  for_each = local.enable_cloudformatian_s3_template_store ? local.s3_object_presign : []

  program = ["/bin/bash", "external-data-scripts/s3-object-presign.sh"]
  query = {
    s3_path = each.value
  }

  depends_on = [
    aws_s3_bucket.cloudformation_custom_stack_template_store,
  ]
}
