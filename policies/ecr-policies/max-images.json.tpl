{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Only keep ${max_images} latest images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": ${max_images}
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
