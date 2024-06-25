{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Effect": "Allow",
      "Resource": "*",
      "Condition": {
        "ForAnyValue:StringEquals": {
          "cloudwatch:namespace": [
            %{for k, v in namespaces}
            "${v}"%{if k+1 != length(namespaces)},%{endif}
            %{endfor}
          ]
        }
      }
    }
  ]
}
