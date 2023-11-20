{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": ${services}
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
