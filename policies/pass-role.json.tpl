{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": ${role_arns},
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": ${services}
        }
      }
    }
  ]
}
