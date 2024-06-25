{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecs:DescribeClusters"
      ],
      "Effect": "Allow",
      "Resource": [
        %{for k, v in cluster_names}
        "arn:aws:ecs:${region}:${account_id}:cluster/${v}"%{if k+1 != length(cluster_names)},%{endif}
        %{endfor}
      ]
    }
  ]
}
