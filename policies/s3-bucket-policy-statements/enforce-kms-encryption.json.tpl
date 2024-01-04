%{if bucket_arn != ""}{
  "Principal": "*",
  "Action": "s3:PutObject",
  "Effect": "Deny",
  "Resource": [
    "${bucket_arn}/*"
  ],
  "Condition": {
    "StringNotEquals": {
      "s3:x-amz-server-side-encryption": "aws:kms"
    }
  }
}%{endif}
