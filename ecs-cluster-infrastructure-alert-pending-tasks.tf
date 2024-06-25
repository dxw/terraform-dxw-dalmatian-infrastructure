resource "aws_cloudwatch_metric_alarm" "infrastructure_ecs_cluster_pending_task" {
  count = local.enable_infrastructure_ecs_cluster_pending_task_alert ? 1 : 0

  alarm_name          = "${local.resource_prefix}-infrastructure-ecs-cluster-infrastructure-pending-task"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = local.infrastructure_ecs_cluster_pending_task_alert_evaluation_periods
  metric_name         = "PendingTasksCount"
  namespace           = "ECS"
  period              = local.infrastructure_ecs_cluster_pending_task_alert_period
  statistic           = "Maximum"
  threshold           = local.infrastructure_ecs_cluster_pending_task_alert_threshold
  alarm_description   = "Pending Tasks for ${aws_ecs_cluster.infrastructure[0].name} Cluster"
  actions_enabled     = "true"
  alarm_actions = concat(
    local.infrastructure_ecs_cluster_pending_task_alert_slack ? [data.aws_sns_topic.infrastructure_slack_sns_topic[0].arn] : [],
    local.infrastructure_ecs_cluster_pending_task_alert_opsgenie ? [data.aws_sns_topic.infrastructure_opsgenie_sns_topic[0].arn] : []
  )
  ok_actions = concat(
    local.infrastructure_ecs_cluster_pending_task_alert_slack ? [data.aws_sns_topic.infrastructure_slack_sns_topic[0].arn] : [],
    local.infrastructure_ecs_cluster_pending_task_alert_opsgenie ? [data.aws_sns_topic.infrastructure_opsgenie_sns_topic[0].arn] : []
  )
  dimensions = {
    ClusterName = aws_ecs_cluster.infrastructure[0].name
  }
}
