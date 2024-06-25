resource "aws_cloudwatch_metric_alarm" "infrastructure_ecs_cluster_asg_cpu" {
  count = local.enable_infrastructure_ecs_cluster_asg_cpu_alert ? 1 : 0

  alarm_name          = "${local.resource_prefix}-infrastructure-ecs-cluster-asg-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = local.infrastructure_ecs_cluster_asg_cpu_alert_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = local.infrastructure_ecs_cluster_asg_cpu_alert_period
  statistic           = "Maximum"
  threshold           = local.infrastructure_ecs_cluster_asg_cpu_alert_threshold
  alarm_description   = "CPU Utilization for ${aws_ecs_cluster.infrastructure[0].name}'s Auto Scaling Group"
  actions_enabled     = "true"
  alarm_actions = concat(
    local.infrastructure_ecs_cluster_asg_cpu_alert_slack ? [data.aws_sns_topic.infrastructure_slack_sns_topic[0].arn] : [],
    local.infrastructure_ecs_cluster_asg_cpu_alert_opsgenie ? [data.aws_sns_topic.infrastructure_opsgenie_sns_topic[0].arn] : []
  )
  ok_actions = concat(
    local.infrastructure_ecs_cluster_asg_cpu_alert_slack ? [data.aws_sns_topic.infrastructure_slack_sns_topic[0].arn] : [],
    local.infrastructure_ecs_cluster_asg_cpu_alert_opsgenie ? [data.aws_sns_topic.infrastructure_opsgenie_sns_topic[0].arn] : []
  )
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.infrastructure_ecs_cluster[0].name
  }
}
