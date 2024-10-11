resource "aws_cloudwatch_log_group" "infrastructure_ecs_cluster_datadog_agent" {
  count = local.enable_infrastructure_ecs_cluster_datadog_agent ? 1 : 0

  name              = "${local.resource_prefix_hash}-infrastructure-ecs-cluster-datadog-agent-logs"
  retention_in_days = 7
  kms_key_id        = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  skip_destroy      = true
}

resource "aws_iam_role" "infrastructure_ecs_cluster_datadog_agent_task_execution" {
  count = local.enable_infrastructure_ecs_cluster_datadog_agent ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-datadog-agent-task-execution"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-datadog-agent-task-execution"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["ecs-tasks.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_datadog_agent_task_execution_ecr_pull" {
  count = local.enable_infrastructure_ecs_cluster_datadog_agent ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-datadog-agent-task-execution-ecr-pull"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-datadog-agent-task-execution-ecr-pull"
  policy = templatefile(
    "${path.root}/policies/ecr-pull.json.tpl",
    { ecr_repository_arn = aws_ecr_repository.infrastructure_ecs_cluster_datadog_agent[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_datadog_agent_task_execution_ecr_pull" {
  count = local.enable_infrastructure_ecs_cluster_datadog_agent ? 1 : 0

  role       = aws_iam_role.infrastructure_ecs_cluster_datadog_agent_task_execution[0].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_datadog_agent_task_execution_ecr_pull[0].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_datadog_agent_task_execution_cloudwatch_logs" {
  count = local.enable_infrastructure_ecs_cluster_datadog_agent ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-datadog-agent-task-execution-cloudwatch-logs"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-datadog-agent-task-execution-cloudwatch-logs"
  policy      = templatefile("${path.root}/policies/cloudwatch-logs-rw.json.tpl", {})
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_datadog_agent_task_execution_cloudwatch_logs" {
  count = local.enable_infrastructure_ecs_cluster_datadog_agent ? 1 : 0

  role       = aws_iam_role.infrastructure_ecs_cluster_datadog_agent_task_execution[0].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_datadog_agent_task_execution_cloudwatch_logs[0].arn
}

resource "aws_iam_policy" "infrastructure_ecs_cluster_datadog_agent_task_execution_get_secret_value" {
  count = local.enable_infrastructure_ecs_cluster_datadog_agent ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-datadog-agent-task-execution-get-secret-value"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-datadog-agent-task-execution-get-secret-value"
  policy = templatefile("${path.root}/policies/secrets-manager-get-secret-value.json.tpl", {
    secret_name_arns = jsonencode([
      aws_secretsmanager_secret.infrastructure_ecs_cluster_datadog_agent_api_key[0].arn
    ])
  })
}

resource "aws_iam_role_policy_attachment" "infrastructure_ecs_cluster_datadog_agent_task_execution_get_secret_value" {
  count = local.enable_infrastructure_ecs_cluster_datadog_agent ? 1 : 0

  role       = aws_iam_role.infrastructure_ecs_cluster_datadog_agent_task_execution[0].name
  policy_arn = aws_iam_policy.infrastructure_ecs_cluster_datadog_agent_task_execution_get_secret_value[0].arn
}

resource "aws_ecs_task_definition" "infrastructure_ecs_cluster_datadog_agent" {
  count = local.enable_infrastructure_ecs_cluster_datadog_agent ? 1 : 0

  family = "${local.resource_prefix}-ecs-cluster-infrastruture-datadog-agent"
  container_definitions = templatefile(
    "./container-definitions/app.json.tpl",
    {
      container_name      = "datadog-agent"
      image               = aws_ecr_repository.infrastructure_ecs_cluster_datadog_agent[0].repository_url
      entrypoint          = jsonencode([])
      command             = jsonencode([])
      environment_file_s3 = ""
      environment = jsonencode([
        {
          name  = "DD_SITE",
          value = local.infrastructure_datadog_site
        },
        #{
        #  name  = "DD_LOG_LEVEL",
        #  value = "debug"
        #},
        #{
        #  name  = "DD_HOSTNAME"
        #  value = "${local.resource_prefix}-ecs-cluster"
        #},
        {
          name  = "DD_APM_ENABLED"
          value = "false"
        },
        {
          name  = "DD_ENV"
          value = local.environment
        },
        {
          name  = "DD_LOGS_ENABLED"
          value = "true"
        },
        {
          name  = "DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL"
          value = "true"
        },
        {
          name  = "DD_PROCESS_AGENT_ENABLED"
          value = "true"
        },
        {
          name  = "DD_CONTAINER_LABELS_AS_TAGS"
          value = jsonencode({ "my.custom.label.team" = "team" })
        },
        {
          name  = "DD_TAGS"
          value = jsonencode({ "environment" = local.environment, "project" = local.resource_prefix, })
        },
        {
          name  = "DD_DOGSTATSD_NON_LOCAL_TRAFFIC"
          value = "true"
        },
        {
          name  = "DD_SYSTEM_PROBE_NETWORK_ENABLED"
          value = "true"
        },
        {
          name  = "DD_SYSTEM_PROBE_SERVICE_MONITORING_ENABLED"
          value = "true"
        },
        {
          name  = "DD_RUNTIME_SECURITY_CONFIG_ENABLED"
          value = "true"
        },
        {
          name  = "DD_RUNTIME_SECURITY_CONFIG_NETWORK_ENABLED"
          value = "true"
        },
        {
          name  = "HOST_ROOT"
          value = "/host/root"
        }
      ])
      secrets = jsonencode([
        {
          name      = "DD_API_KEY"
          valueFrom = aws_secretsmanager_secret.infrastructure_ecs_cluster_datadog_agent_api_key[0].arn
        }
      ])
      container_port = 0
      extra_hosts    = jsonencode([])
      volumes = jsonencode([
        {
          sourceVolume  = "dockersock"
          containerPath = "/var/run/docker.sock"
          readonly      = true
        },
        {
          sourceVolume  = "proc"
          containerPath = "/host/proc/"
          readonly      = true
        },
        {
          sourceVolume  = "cgroup"
          containerPath = "/host/sys/fs/cgroup"
          readonly      = true
        },
        {
          sourceVolume  = "debug"
          containerPath = "/sys/kernel/debug"
        },
        {
          sourceVolume  = "modules"
          containerPath = "/lib/modules"
        },
        {
          sourceVolume  = "usr-src"
          containerPath = "/usr/src"
        },
        {
          sourceVolume  = "probe-build"
          containerPath = "/var/tmp/datadog-agent/system-probe/build"
        },
        {
          sourceVolume  = "probe-kernel-headers"
          containerPath = "/var/tmp/datadog-agent/system-probe/kernel-headers"
        },
        {
          sourceVolume  = "apt"
          containerPath = "/host/etc/apt"
        },
        {
          sourceVolume  = "yum-repos"
          containerPath = "/host/etc/yum.repos.d"
        },
        {
          sourceVolume  = "zypp"
          containerPath = "/host/etc/zypp"
        },
        {
          sourceVolume  = "pki"
          containerPath = "/host/etc/pki"
        },
        {
          sourceVolume  = "yum-vars"
          containerPath = "/host/etc/yum/vars"
        },
        {
          sourceVolume  = "dnf-vars"
          containerPath = "/host/etc/dnf/vars"
        },
        {
          sourceVolume  = "rhsm"
          containerPath = "/host/etc/rhsm"
        }
      ])
      linux_parameters = jsonencode({
        capabilities = {
          add = [
            "SYS_ADMIN",
            "SYS_RESOURCE",
            "SYS_PTRACE",
            "NET_ADMIN",
            "NET_BROADCAST",
            "NET_RAW",
            "IPC_LOCK",
            "CHOWN"
          ]
        }
      })
      security_options      = jsonencode([])
      syslog_address        = ""
      syslog_tag            = ""
      cloudwatch_log_group  = aws_cloudwatch_log_group.infrastructure_ecs_cluster_datadog_agent[0].name
      awslogs_stream_prefix = ""
      region                = local.aws_region
    }
  )

  volume {
    name      = "dockersock"
    host_path = "/var/run/docker.sock"
  }
  volume {
    name      = "proc"
    host_path = "/proc/"
  }
  volume {
    name      = "cgroup"
    host_path = "/sys/fs/cgroup/"
  }
  volume {
    name      = "debug"
    host_path = "/sys/kernel/debug"
  }
  volume {
    name      = "modules"
    host_path = "/lib/modules"
  }
  volume {
    name      = "usr-src"
    host_path = "/usr/src"
  }
  volume {
    name      = "probe-build"
    host_path = "/var/tmp/datadog-agent/system-probe/build"
  }
  volume {
    name      = "probe-kernel-headers"
    host_path = "/var/tmp/datadog-agent/system-probe/kernel-headers"
  }
  volume {
    name      = "apt"
    host_path = "/etc/apt"
  }
  volume {
    name      = "yum-repos"
    host_path = "/etc/yum.repos.d"
  }
  volume {
    name      = "zypp"
    host_path = "/etc/zypp"
  }
  volume {
    name      = "pki"
    host_path = "/etc/pki"
  }
  volume {
    name      = "yum-vars"
    host_path = "/etc/yum/vars"
  }
  volume {
    name      = "dnf-vars"
    host_path = "/etc/dnf/vars"
  }
  volume {
    name      = "dockersock"
    host_path = "/var/run/docker.sock"
  }
  volume {
    name      = "rhsm"
    host_path = "/etc/rhsm"
  }
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = aws_iam_role.infrastructure_ecs_cluster_datadog_agent_task_execution[0].arn
}

resource "aws_ecs_service" "infrastructure_ecs_cluster_datadog_agent" {
  count = local.enable_infrastructure_ecs_cluster_datadog_agent ? 1 : 0

  name                = "datadog-agent"
  cluster             = aws_ecs_cluster.infrastructure[0].name
  task_definition     = aws_ecs_task_definition.infrastructure_ecs_cluster_datadog_agent[0].arn
  scheduling_strategy = "DAEMON"
}
