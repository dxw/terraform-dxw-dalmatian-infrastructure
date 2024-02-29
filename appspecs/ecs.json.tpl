{
  "Resources": [
    {
      "TargetService": {
        "Type": "AWS::ECS::Service",
        "Properties": {
          "TaskDefinition": "${task_definition_arn}",
          "LoadBalancerInfo": {
            "ContainerName": "${container_name}",
            "ContainerPort": ${container_port}
          }
        }
      }
    }
  ]
}
