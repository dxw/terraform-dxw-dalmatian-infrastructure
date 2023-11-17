{
  "Principal": "*",
  "Action": "s3:*",
  "Effect": "Deny",
  "Resource": [
    "${bucket_arn}",
    "${bucket_arn}/*"
  ],
  "Condition": {
    "Bool": {
      "aws:SecureTransport": "false"
    },
    "NumericLessThan": {
      "s3:TlsVersion": "1.2"
    }
  }
}
