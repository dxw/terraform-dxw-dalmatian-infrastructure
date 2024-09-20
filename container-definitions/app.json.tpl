[
  {
    "image": "${image}",
    "name": "${container_name}",
    %{ if syslog_address != "" }
    "logConfiguration": {
      "logDriver": "syslog",
      "options": {
        "syslog-address": "${syslog_address}",
        "tag": "${syslog_tag}"
      }
    },
    %{else}
    %{ if cloudwatch_log_group != "" }
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        %{ if awslogs_stream_prefix != "" }
        "awslogs-stream-prefix": "${awslogs_stream_prefix}",
        %{ endif }
        "awslogs-group": "${cloudwatch_log_group}",
        "awslogs-region": "${region}"
      }
    },
    %{ else }
    "logConfiguration": {
      "logDriver": "json-file"
    },
    %{ endif }
    %{ endif }
    %{ if volumes != "[]" }
    "mountPoints": ${volumes},
    %{ endif }
    %{ if container_port != 0 }
    "portMappings": [
      {
        "hostPort": 0,
        "protocol": "tcp",
        "containerPort": ${container_port}
      }
    ],
    %{ endif }
    %{ if environment != "[]" }
    "environment": ${environment},
    %{ endif }
    %{ if secrets != "[]" }
    "secrets": ${secrets},
    %{ endif }
    %{ if environment_file_s3 != "" }
    "environmentFiles": [
      {
        "value": "${environment_file_s3}",
        "type": "s3"
      }
    ],
    %{ endif }
    %{ if extra_hosts != "[]" }
    "extraHosts": ${extra_hosts},
    %{ endif }
    %{ if linux_parameters != "{}" }
    "linuxParameters": ${linux_parameters},
    %{ endif }
    %{if entrypoint != "[]"}
    "entrypoint": ${entrypoint},
    %{ endif }
    %{if command != "[]"}
    "command": ${command},
    %{ endif }
    "memoryReservation": 16,
    %{ if enable_nginx_frontend }
    "dependsOn": [
      {
        "containerName": "${container_name}-nginx",
        "condition": "HEALTHY"
      }
    ],
    %{ endif }
    "essential": true
  }
  %{ if enable_nginx_frontend },
  {
    "image": "nginx:${nginx_image_tag}",
    "name": "${container_name}-nginx",
    %{ if syslog_address != "" }
    "logConfiguration": {
      "logDriver": "syslog",
      "options": {
        "syslog-address": "${syslog_address}",
        "tag": "${syslog_tag}"
      }
    },
    %{else}
    %{ if cloudwatch_log_group != "" }
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        %{ if awslogs_stream_prefix != "" }
        "awslogs-stream-prefix": "${awslogs_stream_prefix}",
        %{ endif }
        "awslogs-group": "${cloudwatch_log_group}",
        "awslogs-region": "${region}"
      }
    },
    %{ else }
    "logConfiguration": {
      "logDriver": "json-file"
    },
    %{ endif }
    %{ endif }
    "portMappings": [
      {
        "hostPort": 0,
        "protocol": "tcp",
        "containerPort": 8080
      }
    ],
    %{ if nginx_environment != "[]" }
    "environment": ${nginx_environment},
    %{ endif }
    %{if nginx_entrypoint != "[]"}
    "entrypoint": ${nginx_entrypoint},
    %{ endif }
    "memoryReservation": 16,
    "essential": true.
    "healthCheck": {
      "command": ["CMD-SHELL", "service", "nginx", "status"]
    }
  }
  %{ endif }
]
