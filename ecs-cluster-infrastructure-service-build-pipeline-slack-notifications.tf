resource "aws_cloudwatch_event_rule" "infrastructure_ecs_cluster_service_pipeline_slack_notifications" {
  count = local.infrastructure_ecs_cluster_service_pipeline_slack_notifications ? 1 : 0

  name        = "${local.resource_prefix_hash}-ecs-service-pipeline-slack-notifications"
  description = "${local.resource_prefix} ECS service pipeline execution state changes to Slack"
  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      pipeline = [for k, v in aws_codepipeline.infrastructure_ecs_cluster_service : v.name]
      state    = ["STARTED", "SUCCEEDED", "FAILED", "STOPPED", "SUPERSEDED"]
    }
  })
}

resource "aws_cloudwatch_event_target" "infrastructure_ecs_cluster_service_pipeline_slack_notifications" {
  count = local.infrastructure_ecs_cluster_service_pipeline_slack_notifications ? 1 : 0

  target_id = "${local.resource_prefix_hash}-ecs-service-pipeline-slack-notifications"
  rule      = aws_cloudwatch_event_rule.infrastructure_ecs_cluster_service_pipeline_slack_notifications[0].name
  arn       = data.aws_sns_topic.infrastructure_slack_sns_topic[0].arn
}
