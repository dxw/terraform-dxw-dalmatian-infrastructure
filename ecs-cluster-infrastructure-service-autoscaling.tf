# Every service is registered as a scalable target so that Terraform can stop
# managing desired_count without breaking container_count: registering a
# target moves the current count inside [min, max], so a service without an
# autoscaling block runs exactly container_count tasks.
resource "aws_appautoscaling_target" "infrastructure_ecs_cluster_service" {
  for_each = local.infrastructure_ecs_cluster_services

  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
  resource_id        = "service/${aws_ecs_cluster.infrastructure[0].name}/${aws_ecs_service.infrastructure_ecs_cluster_service[each.key].name}"
  min_capacity       = each.value["autoscaling"] != null ? each.value["autoscaling"]["min_count"] : each.value["container_count"]
  max_capacity       = each.value["autoscaling"] != null ? each.value["autoscaling"]["max_count"] : each.value["container_count"]

  lifecycle {
    precondition {
      condition     = each.value["autoscaling"] == null || (each.value["container_port"] != null && each.value["container_port"] != 0)
      error_message = "Service ${each.key}: autoscaling needs a container_port, because ALBRequestCountPerTarget is measured on a target group."
    }

    # Checked here rather than on the variable so a block supplied through
    # the service defaults is covered too. min_count must be at least 1: with
    # no tasks there are no targets, RequestCountPerTarget has no datapoints,
    # FILL(..., 0) reads as zero demand and the service could never scale
    # out again.
    precondition {
      condition     = each.value["autoscaling"] == null || (each.value["autoscaling"]["min_count"] >= 1 && each.value["autoscaling"]["min_count"] <= each.value["autoscaling"]["max_count"])
      error_message = "Service ${each.key}: autoscaling.min_count must be at least 1 and no more than autoscaling.max_count."
    }
  }
}

resource "aws_appautoscaling_policy" "infrastructure_ecs_cluster_service_requests" {
  for_each = local.infrastructure_ecs_cluster_service_autoscaling_policies

  name               = "${local.resource_prefix}-${each.key}-requests-per-target"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.infrastructure_ecs_cluster_service[each.key].service_namespace
  scalable_dimension = aws_appautoscaling_target.infrastructure_ecs_cluster_service[each.key].scalable_dimension
  resource_id        = aws_appautoscaling_target.infrastructure_ecs_cluster_service[each.key].resource_id

  target_tracking_scaling_policy_configuration {
    target_value       = each.value["autoscaling"]["target_requests_per_target"]
    scale_in_cooldown  = each.value["autoscaling"]["scale_in_cooldown"]
    scale_out_cooldown = each.value["autoscaling"]["scale_out_cooldown"]

    customized_metric_specification {
      dynamic "metrics" {
        for_each = { for i, suffix in each.value["target_group_arn_suffixes"] : "tg${i}" => suffix }

        content {
          id          = metrics.key
          return_data = false

          metric_stat {
            stat = "Sum"

            metric {
              namespace   = "AWS/ApplicationELB"
              metric_name = "RequestCountPerTarget"

              dimensions {
                name  = "TargetGroup"
                value = metrics.value
              }

              dimensions {
                name  = "LoadBalancer"
                value = aws_alb.infrastructure_ecs_cluster_service[0].arn_suffix
              }
            }
          }
        }
      }

      metrics {
        id          = "requests_per_target"
        label       = "ALB requests per target per minute, summed over the service's target groups"
        expression  = join(" + ", [for i, suffix in each.value["target_group_arn_suffixes"] : "FILL(tg${i}, 0)"])
        return_data = true
      }
    }
  }
}
