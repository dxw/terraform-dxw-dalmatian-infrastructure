# Managed termination protection is deliberately off: it sets scale-in
# protection on instances running tasks, and an instance refresh (run
# nightly by the instance-refresh Lambda) waits an hour for protected
# instances and then fails. Draining stays with the existing lifecycle hook
# and Lambda, so managed draining is off too.
resource "aws_ecs_capacity_provider" "infrastructure_ecs_cluster" {
  count = local.infrastructure_ecs_cluster_capacity_provider_enabled ? 1 : 0

  name = local.infrastructure_ecs_cluster_capacity_provider_name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.infrastructure_ecs_cluster[0].arn
    managed_termination_protection = "DISABLED"
    managed_draining               = "DISABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = local.infrastructure_ecs_cluster_capacity_provider["target_capacity"]
      minimum_scaling_step_size = local.infrastructure_ecs_cluster_capacity_provider["minimum_scaling_step_size"]
      maximum_scaling_step_size = local.infrastructure_ecs_cluster_capacity_provider["maximum_scaling_step_size"]
      instance_warmup_period    = local.infrastructure_ecs_cluster_capacity_provider["instance_warmup_period"]
    }
  }

  lifecycle {
    precondition {
      condition     = !can(regex("^(aws|ecs|fargate)", local.infrastructure_ecs_cluster_capacity_provider_name))
      error_message = "ECS rejects capacity provider names that start with aws, ecs or fargate; the name is derived from project_name (${local.infrastructure_ecs_cluster_capacity_provider_name})."
    }

    precondition {
      condition     = local.infrastructure_ecs_cluster_draining_lambda_enabled
      error_message = "infrastructure_ecs_cluster_capacity_provider needs infrastructure_ecs_cluster_draining_lambda_enabled = true: managed scale-in terminates instances that may run tasks, and only the draining Lambda moves them first."
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "infrastructure_ecs_cluster" {
  count = local.infrastructure_ecs_cluster_capacity_provider_enabled ? 1 : 0

  cluster_name       = aws_ecs_cluster.infrastructure[0].name
  capacity_providers = [aws_ecs_capacity_provider.infrastructure_ecs_cluster[0].name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.infrastructure_ecs_cluster[0].name
    weight            = 1
    base              = 0
  }
}
