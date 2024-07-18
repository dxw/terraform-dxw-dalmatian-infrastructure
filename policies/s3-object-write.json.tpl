{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": [
        "${bucket_arn}${path}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "s3:GetEncryptionConfiguration",
      "Resource": [
        "${bucket_arn}"
      ]
    }
  ]
}
