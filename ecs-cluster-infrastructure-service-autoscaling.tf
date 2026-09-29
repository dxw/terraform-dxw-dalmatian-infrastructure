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
