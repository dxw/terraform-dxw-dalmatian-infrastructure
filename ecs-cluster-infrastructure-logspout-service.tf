resource "aws_ecs_task_definition" "infrastructure_ecs_cluster_logspout" {
  count = local.infrastrucutre_ecs_cluster_logspout_enabled ? 1 : 0

  family = "${local.resource_prefix}-ecs-infrastructure-logsput"
  container_definitions = templatefile(
    "./container-definitions/app.json.tpl",
    {
      container_name      = "logspout"
      image               = aws_ecr_repository.infrastructure_ecs_cluster_logspout[0].repository_url
      entrypoint          = jsonencode([])
      command             = jsonencode([local.infrastructure_ecs_cluster_syslog_endpoint])
      environment_file_s3 = ""
      environment         = jsonencode([])
      secrets             = jsonencode([])
      container_port      = 0
      extra_hosts         = jsonencode([])
      volumes = jsonencode([
        {
          sourceVolume  = "dockersock"
          containerPath = "/var/run/docker.sock"
        }
      ])
      linux_parameters      = jsonencode({})
      cloudwatch_log_group  = ""
      awslogs_stream_prefix = ""
      region                = local.aws_region
    }
  )

  volume {
    name      = "dockersock"
    host_path = "/var/run/docker.sock"
  }
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
}

resource "aws_ecs_service" "infrastructure_ecs_cluster_logspout" {
  count = local.infrastrucutre_ecs_cluster_logspout_enabled ? 1 : 0

  name                = "logsput"
  cluster             = aws_ecs_cluster.infrastructure[0].name
  task_definition     = aws_ecs_task_definition.infrastructure_ecs_cluster_logspout[0].arn
  scheduling_strategy = "DAEMON"
}
