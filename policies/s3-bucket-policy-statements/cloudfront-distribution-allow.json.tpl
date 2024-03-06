{
  "Effect": "Allow",
  "Principal": {
    "Service": "cloudfront.amazonaws.com"
  },
  "Action": "s3:GetObject",
  "Resource": "${bucket_arn}/*",
  "Condition": {
    "StringEquals": {
      "AWS:SourceArn": ${cloudfront_distribution_arns}
    }
  }
}
