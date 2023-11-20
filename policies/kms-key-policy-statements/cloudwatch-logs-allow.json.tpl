%{if log_group_arn != ""}{
  "Effect": "Allow",
  "Principal": {
    "Service": "logs.amazonaws.com"
  },
  "Action": [
    "kms:Encrypt*",
    "kms:Decrypt*",
    "kms:ReEncrypt*",
    "kms:GenerateDataKey*",
    "kms:Describe*"
  ],
  "Resource": "*",
  "Condition": {
    "ArnEquals": {
      "kms:EncryptionContext:aws:logs:arn": "${log_group_arn}"
    }
  }
}%{endif}
