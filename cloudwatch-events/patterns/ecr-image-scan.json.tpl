{
  "detail-type": ["ECR Image Scan"],
  "source": ["aws.ecr"],
  "detail": {
    "repository-name": [{
      "prefix": "${ecr_repository_name}"
    }]
  }
}
