%{if role_arns != "[]"}{
  "Effect": "Allow",
  "Principal": {
    "AWS": ${role_arns}
  },
  "Action": [
    "kms:GenerateDataKey*",
    "kms:Decrypt"
  ],
  "Resource": "*"
}%{endif}
