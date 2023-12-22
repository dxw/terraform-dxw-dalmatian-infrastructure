{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "${role_arn}",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": [
            "${service}"
          ]
        }
      }
    }
  ]
}
