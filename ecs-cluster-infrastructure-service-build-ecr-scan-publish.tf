resource "aws_cloudwatch_event_rule" "infrastructure_ecs_cluster_service_ecr_scan" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["ecr_scan_target_sns_topic_arn"] != null
  }

  name        = "${local.resource_prefix}-${each.key}-ecr-image-scan"
  description = "Triggered when image scan has completed on ECR ${aws_ecr_repository.infrastructure_ecs_cluster_service[each.key].name}"
  event_pattern = templatefile(
    "${path.root}/cloudwatch-events/patterns/ecr-image-scan.json.tpl",
    { ecr_repository_name = aws_ecr_repository.infrastructure_ecs_cluster_service[each.key].name }
  )
}

resource "aws_cloudwatch_event_target" "ecr_scan_event_target" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["ecr_scan_target_sns_topic_arn"] != null
  }

  rule = aws_cloudwatch_event_rule.infrastructure_ecs_cluster_service_ecr_scan[each.key].name
  arn  = each.value["ecr_scan_target_sns_topic_arn"]

  input_transformer {
    input_paths = {
      status     = "$.detail.scan-status",
      repo       = "$.detail.repository-name",
      account_id = "$.account",
      findings   = "$.detail.finding-severity-counts",
      digest     = "$.detail.image-digest",
      image_tags = "$.detail.image-tags"
      scan_time  = "$.time"
    }
    input_template = templatefile("${path.root}/cloudwatch-events/target-imput-templates/ecr-image-scan.txt.tpl", {})
  }
}
