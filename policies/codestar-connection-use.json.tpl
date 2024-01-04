{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "codestar-connections:UseConnection"
      ],
      "Effect": "Allow",
      "Resource": [
        "${codestar_connection_arn}"
      ]
    }
  ]
}
