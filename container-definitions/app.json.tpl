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
    %{ if security_options != "[]" }
    "dockerSecurityOptions": ${security_options},
    %{ endif }
    %{if entrypoint != "[]"}
    "entrypoint": ${entrypoint},
    %{ endif }
    %{if command != "[]"}
    "command": ${command},
    %{ endif }
    "memoryReservation": 16,
    "essential": true
  }
]
