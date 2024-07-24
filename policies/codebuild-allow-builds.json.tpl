{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "codebuild:StartBuild",
        "codebuild:StopBuild",
        "codebuild:BatchGet*",
        "codebuild:Get*",
        "codebuild:List*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
