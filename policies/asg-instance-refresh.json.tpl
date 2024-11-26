{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "autoscaling:StartInstanceRefresh",
      "Resource": ${asg_arns}
    }
  ]
}
