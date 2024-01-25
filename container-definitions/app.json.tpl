[
  {
    "essential": true,
    "memoryReservation": 16,
    "image": "${image}",
    "name": "${container_name}",
    %{ if cloudwatch_log_group != "" }
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${cloudwatch_log_group}",
        "awslogs-region": "${region}"
      }
    },
    %{ else }
    "logConfiguration": {
      "logDriver": "json-file"
    },
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
    "entrypoint": ${entrypoint}
  }
]
