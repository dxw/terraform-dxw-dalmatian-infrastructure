resource "aws_alb_target_group" "infrastructure_ecs_cluster_service" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["deployment_type"] == "rolling" && v["container_port"] != 0
  }

  name = "${local.resource_prefix_hash}-${each.key}"

  port        = "80"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.infrastructure[0].id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = each.value["container_heath_check_path"]
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200,301,302"
  }

  deregistration_delay = each.value["deregistration_delay"]
}

resource "aws_alb_target_group" "infrastructure_ecs_cluster_service_blue" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["deployment_type"] == "blue-green" && v["container_port"] != 0
  }

  name = "${local.resource_prefix_hash}-b-${each.key}"

  port        = "80"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.infrastructure[0].id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = each.value["container_heath_check_path"]
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200,301,302"
  }

  deregistration_delay = each.value["deregistration_delay"]
}

resource "aws_alb_target_group" "infrastructure_ecs_cluster_service_green" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["deployment_type"] == "blue-green" && v["container_port"] != 0
  }

  name = "${local.resource_prefix_hash}-g-${each.key}"

  port        = "80"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.infrastructure[0].id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = each.value["container_heath_check_path"]
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200,301,302"
  }

  deregistration_delay = each.value["deregistration_delay"]
}
