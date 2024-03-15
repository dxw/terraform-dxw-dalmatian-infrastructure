[
  {
    "essential": true,
    "memoryReservation": null,
    "image": "${image}",
    "name": "${container_name}",
    "memoryReservation": 128,
    "logConfiguration": {
      "logDriver": "json-file"
    },
    "portMappings": [
    ],
    "entrypoint": ${entrypoint},
    %{ if environment != "[]" }
    "environment": ${environment}%{ if secrets != "[]" },{% endif }
    %{ endif }
    %{ if secrets != "[]" }
    "secrets": ${secrets}
    %{ endif }
  }
]
