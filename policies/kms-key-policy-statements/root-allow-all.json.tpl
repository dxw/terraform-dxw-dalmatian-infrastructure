{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::${aws_account_id}:root"
  },
  "Action": "kms:*",
  "Resource": "*"
}
