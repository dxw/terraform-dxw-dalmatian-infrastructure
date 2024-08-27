%{if s3_source_arns != "[]"}{
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
      "aws:SourceArn": ${s3_source_arns}
    },
    "StringEquals": {
      "aws:SourceAccount": "${account_id}"
    }
  }
}%{if logs_source_arns != "[]"},%{endif}%{endif}
%{if logs_source_arns != "[]"}{
  "Effect": "Allow",
  "Principal": {
    "Service": "delivery.logs.amazonaws.com"
  },
  "Action": [
      "s3:GetBucketAcl"
  ],
  "Resource": "${log_bucket_arn}",
  "Condition": {
    "StringEquals": {
      "aws:SourceAccount": "${account_id}"
    },
    "ArnLike": {
      "aws:SourceArn": ${logs_source_arns}
    }
  }
},
{
  "Effect": "Allow",
  "Principal": {
    "Service": "delivery.logs.amazonaws.com"
  },
  "Action": "s3:PutObject",
  "Resource": "${log_bucket_arn}%{if vpc_flow_logs_prefix != "" }/${vpc_flow_logs_prefix}%{endif}/AWSLogs/${account_id}/*",
  "Condition": {
    "StringEquals": {
      "s3:x-amz-acl": "bucket-owner-full-control",
      "aws:SourceAccount": "${account_id}"
    },
    "ArnLike": {
      "aws:SourceArn": ${logs_source_arns}
    }
  }
}%{endif}
