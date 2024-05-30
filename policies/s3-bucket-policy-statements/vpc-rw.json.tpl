{
  "Effect": "Allow",
  "Principal": "*",
  "Action": "s3:*",
  "Resource": "${bucket_arn}/*",
  "Condition": {
    "StringEquals": {
      "aws:sourceVpc": ${vpc_ids}
    }
  }
}
