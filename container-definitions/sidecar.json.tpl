{
  "image": "${image}",
  "name": "${name}",
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
      "awslogs-stream-prefix": "${name}",
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
  %{ if environment != "[]" }
  "environment": ${environment},
  %{ endif }
  %{ if command != "[]" }
  "command": ${command},
  %{ endif }
  "memoryReservation": ${memory_reservation},
  "essential": ${essential}
}
