%{if sns_topic_arn != ""}{
  "Effect": "Allow",
  "Principal": {
    "Service": ${services}
  },
  "Action": [
    "kms:GenerateDataKey*",
    "kms:Decrypt"
  ],
  "Resource": "*",
  "Condition": {
    "StringEquals": {
      "kms:EncryptionContext:aws:sns:topicArn": "${sns_topic_arn}"
    }
  }
}%{endif}
