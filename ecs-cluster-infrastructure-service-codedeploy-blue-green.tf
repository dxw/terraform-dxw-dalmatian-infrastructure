resource "aws_codedeploy_app" "infrastructure_ecs_cluster_service_blue_green" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["deployment_type"] == "blue-green"
  }

  compute_platform = "ECS"
  name             = "${local.resource_prefix}-ecs-service-b-g-${each.key}"
}

resource "aws_codedeploy_deployment_config" "infrastructure_ecs_cluster_service_blue_green" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["deployment_type"] == "blue-green"
  }

  deployment_config_name = "${local.resource_prefix}-ecs-service-b-g-${each.key}"
  compute_platform       = "ECS"

  traffic_routing_config {
    type = "AllAtOnce"
  }
}

resource "aws_iam_role" "infrastructure_ecs_cluster_service_blue_green_codedeploy" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["deployment_type"] == "blue-green"
  }

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-service-blue-green-codedeploy-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-service-blue-green-codedeploy-${each.key}"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["codedeploy.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_blue_green_codedeploy" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["deployment_type"] == "blue-green"
  }

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-service-blue-green-codedeploy-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-service-blue-green-codedeploy-${each.key}"
  policy      = templatefile("${path.root}/policies/ecs-codedeploy.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_blue_green_codedeploy" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["deployment_type"] == "blue-green"
  }

  role       = aws_iam_role.infrastructure_ecs_cluster_service_blue_green_codedeploy[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_blue_green_codedeploy[each.key].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_service_blue_green_codedeploy_kms_encrypt" {
  for_each = local.infrastructure_kms_encryption ? {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["deployment_type"] == "blue-green"
  } : {}

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-service-blue-green-codedeploy-${each.key}-kms-encrypt"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-service-blue-green-codedeploy-${each.key}-kms-encrypt"
  policy = templatefile(
    "${path.root}/policies/kms-encrypt.json.tpl",
    { kms_key_arn = aws_kms_key.infrastructure[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_service_blue_green_codedeploy_kms_encrypt" {
  for_each = local.infrastructure_kms_encryption ? {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["deployment_type"] == "blue-green"
  } : {}

  role       = aws_iam_role.infrastructure_ecs_cluster_service_blue_green_codedeploy[each.key].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_service_blue_green_codedeploy_kms_encrypt[each.key].arn
}

resource "aws_codedeploy_deployment_group" "infrastructure_ecs_cluster_service_blue_green" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["deployment_type"] == "blue-green"
  }

  app_name               = aws_codedeploy_app.infrastructure_ecs_cluster_service_blue_green[each.key].name
  deployment_config_name = aws_codedeploy_deployment_config.infrastructure_ecs_cluster_service_blue_green[each.key].deployment_config_name
  deployment_group_name  = "${local.resource_prefix}-ecs-service-b-g-${each.key}"
  service_role_arn       = aws_iam_role.infrastructure_ecs_cluster_service_blue_green_codedeploy[each.key].arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.infrastructure[0].name
    service_name = each.key
  }

  dynamic "load_balancer_info" {
    for_each = each.value["container_port"] != 0 ? [1] : []
    content {
      target_group_pair_info {
        prod_traffic_route {
          listener_arns = [
            local.enable_infrastructure_wildcard_certificate ? aws_alb_listener.infrastructure_ecs_cluster_service_https[0].arn : aws_alb_listener.infrastructure_ecs_cluster_service_http[0].arn
          ]
        }

        target_group {
          name = aws_alb_target_group.infrastructure_ecs_cluster_service_green[each.key].name
        }

        target_group {
          name = aws_alb_target_group.infrastructure_ecs_cluster_service_blue[each.key].name
        }
      }
    }
  }
}

resource "terraform_data" "infrastructure_ecs_cluster_service_blue_green_create_codedeploy_deployment" {
  for_each = {
    for k, v in local.infrastructure_ecs_cluster_services : k => v if v["deployment_type"] == "blue-green"
  }

  triggers_replace = [
    sha256(templatefile(
      "${path.root}/appspecs/ecs.json.tpl",
      {
        task_definition_arn = aws_ecs_task_definition.infrastructure_ecs_cluster_service[each.key].arn
        container_port      = each.value["container_port"] != null ? each.value["container_port"] : 0
        container_name      = each.key
      }
    )),
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOF
    ${path.root}/local-exec-scripts/create-codedeploy-deployment.sh \
      -a "${aws_codedeploy_app.infrastructure_ecs_cluster_service_blue_green[each.key].name}" \
      -g "${aws_codedeploy_deployment_group.infrastructure_ecs_cluster_service_blue_green[each.key].deployment_group_name}" \
      -A "${replace(templatefile(
    "${path.root}/appspecs/ecs.json.tpl",
    {
      task_definition_arn = aws_ecs_task_definition.infrastructure_ecs_cluster_service[each.key].arn
      container_port      = each.value["container_port"] != null ? each.value["container_port"] : 0
      container_name      = each.key
    }), "\"", "\\\"")}" \
      -S "${sha256(templatefile(
    "${path.root}/appspecs/ecs.json.tpl",
    {
      task_definition_arn = aws_ecs_task_definition.infrastructure_ecs_cluster_service[each.key].arn
      container_port      = each.value["container_port"] != null ? each.value["container_port"] : 0
      container_name      = each.key
}))}"
    EOF
}

depends_on = [
  aws_codepipeline.infrastructure_ecs_cluster_service,
  terraform_data.infrastructure_ecs_cluster_service_env_file,
]
}
