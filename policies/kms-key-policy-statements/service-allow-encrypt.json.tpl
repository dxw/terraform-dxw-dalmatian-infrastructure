%{if services != "[]"}{
  "Effect": "Allow",
  "Principal": {
    "Service": ${services}
  },
  "Action": [
    "kms:GenerateDataKey*",
    "kms:Decrypt"
  ],
  "Resource": "*"
}%{endif}
