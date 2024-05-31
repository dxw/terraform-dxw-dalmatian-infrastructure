%{if vpc_ids != "[]"}{
  "Effect": "Allow",
  "Principal": {
    "AWS": "*"
  },
  "Action": [
    "kms:Encrypt",
    "kms:Decrypt",
    "kms:ReEncrypt*",
    "kms:GenerateDataKey*"
  ],
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "aws:sourceVpc": ${vpc_ids},
      "kms:ViaService": "s3.${region}.amazonaws.com",
      "kms:EncryptionContext:SourceARN": "${bucket_arn}"
    }
  }
}%{endif}
