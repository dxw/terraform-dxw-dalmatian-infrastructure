{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:DescribeImages"
      ],
      "Effect": "Allow",
      "Resource": "${ecr_repository_arn}"
    }
  ]
}
