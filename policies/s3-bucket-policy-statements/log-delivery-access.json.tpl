{
  "Principal": {
    "Service": "logging.s3.amazonaws.com"
  },
  "Action": [
    "s3:PutObject"
  ],
  "Effect": "Allow",
  "Resource": "${log_bucket_arn}/*",
  "Condition": {
    "ArnLike": {
      "aws:SourceArn": ${source_arns}
    },
    "StringEquals": {
      "aws:SourceAccount": "${account_id}"
    }
  }
},
{
  "Effect": "Allow",
  "Principal": {
    "Service": "delivery.logs.amazonaws.com"
  },
  "Action": [
      "s3:GetBucketAcl",
      "s3:ListBucket"
  ],
  "Resource": "${log_bucket_arn}",
  "Condition": {
    "StringEquals": {
      "aws:SourceAccount": "${account_id}"
    },
    "ArnLike": {
      "aws:SourceArn": ${source_arns}
    }
  }
}
