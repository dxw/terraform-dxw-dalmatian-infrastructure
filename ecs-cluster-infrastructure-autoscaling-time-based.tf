resource "aws_autoscaling_schedule" "ecs_infrastructure_time_based_max" {
  for_each = local.enable_infrastructure_ecs_cluster ? local.infrastructure_ecs_cluster_autoscaling_time_based_max : []

  autoscaling_group_name = aws_autoscaling_group.infrastructure_ecs_cluster[0].name
  scheduled_action_name  = "${local.resource_prefix}-time-based-max ${each.value}"
  desired_capacity       = local.infrastructure_ecs_cluster_max_size
  min_size               = -1
  max_size               = -1
  recurrence             = each.value
}

resource "aws_autoscaling_schedule" "ecs_infrastructure_time_based_min" {
  for_each = local.enable_infrastructure_ecs_cluster ? local.infrastructure_ecs_cluster_autoscaling_time_based_min : []

  autoscaling_group_name = aws_autoscaling_group.infrastructure_ecs_cluster[0].name
  scheduled_action_name  = "${local.resource_prefix}-time-based-min ${each.value}"
  desired_capacity       = local.infrastructure_ecs_cluster_min_size
  min_size               = -1
  max_size               = -1
  recurrence             = each.value
}

resource "aws_autoscaling_schedule" "ecs_infrastructure_time_based_custom" {
  for_each = local.enable_infrastructure_ecs_cluster ? local.infrastructure_ecs_cluster_autoscaling_time_based_custom : {}

  autoscaling_group_name = aws_autoscaling_group.infrastructure_ecs_cluster[0].name
  scheduled_action_name  = "${local.resource_prefix}-time-based-custom ${each.value["cron"]}  ${each.value["min"]}-${each.value["max"]}"
  desired_capacity       = each.value["min"]
  min_size               = each.value["min"]
  max_size               = each.value["max"]
  recurrence             = each.value["cron"]
}
