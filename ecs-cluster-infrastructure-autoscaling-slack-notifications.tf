resource "aws_cloudwatch_event_rule" "infrastructure_ecs_cluster_service_autoscaling_slack_notifications" {
  count = length(local.infrastructure_ecs_cluster_autoscaling_slack_notification_services) != 0 ? 1 : 0

  name        = "${local.resource_prefix_hash}-ecs-service-autoscaling-slack-notifications"
  description = "${local.resource_prefix} ECS service target tracking alarms going into ALARM to Slack"
  # Application Auto Scaling emits no events of its own, and EventBridge did
  # not receive the CloudTrail UpdateService calls it makes on our behalf, so
  # the scale-out and scale-in alarms that target tracking creates for each
  # service stand in for them.
  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      alarmName = flatten([
        for service in local.infrastructure_ecs_cluster_autoscaling_slack_notification_services : [
          { prefix = "TargetTracking-service/${aws_ecs_cluster.infrastructure[0].name}/${service}-AlarmHigh-" },
          { prefix = "TargetTracking-service/${aws_ecs_cluster.infrastructure[0].name}/${service}-AlarmLow-" },
        ]
      ])
      state = { value = ["ALARM"] }
    }
  })
}

resource "aws_cloudwatch_event_target" "infrastructure_ecs_cluster_service_autoscaling_slack_notifications" {
  count = length(local.infrastructure_ecs_cluster_autoscaling_slack_notification_services) != 0 ? 1 : 0

  target_id = "${local.resource_prefix_hash}-ecs-service-autoscaling-slack-notifications"
  rule      = aws_cloudwatch_event_rule.infrastructure_ecs_cluster_service_autoscaling_slack_notifications[0].name
  arn       = data.aws_sns_topic.infrastructure_slack_sns_topic[0].arn
}

resource "aws_cloudwatch_event_rule" "infrastructure_ecs_cluster_instances_autoscaling_slack_notifications" {
  count = local.infrastructure_ecs_cluster_autoscaling_slack_notifications ? 1 : 0

  name        = "${local.resource_prefix_hash}-ecs-cluster-instances-slack-notifications"
  description = "${local.resource_prefix} ECS cluster instance scaling and failed launches or terminations to Slack"
  # Instance refresh and max instance lifetime replacements also launch and
  # terminate instances; matching on the scaling Cause keeps that daily churn
  # out of the channel while failures are always sent.
  event_pattern = jsonencode({
    source = ["aws.autoscaling"]
    detail = { AutoScalingGroupName = [aws_autoscaling_group.infrastructure_ecs_cluster[0].name] }
    "$or" = [
      {
        detail-type = ["EC2 Instance Launch Successful", "EC2 Instance Terminate Successful"]
        detail      = { Cause = [{ wildcard = "*triggered policy*" }, { wildcard = "*scheduled action*" }] }
      },
      {
        detail-type = ["EC2 Instance Launch Unsuccessful", "EC2 Instance Terminate Unsuccessful"]
      },
    ]
  })
}

resource "aws_cloudwatch_event_target" "infrastructure_ecs_cluster_instances_autoscaling_slack_notifications" {
  count = local.infrastructure_ecs_cluster_autoscaling_slack_notifications ? 1 : 0

  target_id = "${local.resource_prefix_hash}-ecs-cluster-instances-slack-notifications"
  rule      = aws_cloudwatch_event_rule.infrastructure_ecs_cluster_instances_autoscaling_slack_notifications[0].name
  arn       = data.aws_sns_topic.infrastructure_slack_sns_topic[0].arn
}

resource "aws_cloudwatch_event_rule" "infrastructure_ecs_cluster_placement_failure_slack_notifications" {
  count = local.infrastructure_ecs_cluster_autoscaling_slack_notifications ? 1 : 0

  name        = "${local.resource_prefix_hash}-ecs-placement-failure-slack-notifications"
  description = "${local.resource_prefix} ECS service task placement failures to Slack"
  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Service Action"]
    detail = {
      clusterArn = [aws_ecs_cluster.infrastructure[0].arn]
      eventName  = ["SERVICE_TASK_PLACEMENT_FAILURE"]
    }
  })
}

resource "aws_cloudwatch_event_target" "infrastructure_ecs_cluster_placement_failure_slack_notifications" {
  count = local.infrastructure_ecs_cluster_autoscaling_slack_notifications ? 1 : 0

  target_id = "${local.resource_prefix_hash}-ecs-placement-failure-slack-notifications"
  rule      = aws_cloudwatch_event_rule.infrastructure_ecs_cluster_placement_failure_slack_notifications[0].name
  arn       = data.aws_sns_topic.infrastructure_slack_sns_topic[0].arn
}
