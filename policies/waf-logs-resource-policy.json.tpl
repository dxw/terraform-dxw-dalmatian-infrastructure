{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:us-east-1:${aws_account_id}:log-group:aws-waf-logs-${resource_prefix}-*:*",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "${aws_account_id}"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:logs:us-east-1:${aws_account_id}:*"
        }
      }
    }
  ]
}
