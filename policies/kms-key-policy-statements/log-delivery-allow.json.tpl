%{if account_id != ""}{
  "Effect": "Allow", 
  "Principal": {
    "Service": [ "delivery.logs.amazonaws.com" ] 
  },
  "Action": [
    "kms:Encrypt",
    "kms:Decrypt",
    "kms:ReEncrypt*",
    "kms:GenerateDataKey*",
    "kms:DescribeKey"
  ],
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "aws:SourceAccount": ["${account_id}"]
    },
    "ArnLike": {
      "aws:SourceArn": ["arn:aws:logs:${region}:${account_id}:*"]
    }
  }
}%{endif}
