{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::${elb_account_id}:root"
  },
  "Action": "s3:PutObject",
  "Resource": "${bucket_arn}/AWSLogs/${account_id}/*"
}
