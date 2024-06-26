resource "aws_cloudwatch_log_group" "ecs_cluster_infrastructure_ecs_asg_diff_metric_lambda_log_group" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert ? 1 : 0

  name              = "/aws/lambda/${local.resource_prefix_hash}-ecs-cluster-infrastructure-ecs-asg-diff-metric"
  kms_key_id        = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  retention_in_days = local.infrastructure_ecs_cluster_ecs_asg_diff_metric_lambda_log_retention
}

resource "aws_iam_role" "ecs_cluster_infrastructure_ecs_asg_diff_metric_lambda" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-infrastructure-ecs-asg-diff-metric"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-infrastructure-ecs-asg-diff-metric"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["lambda.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "ecs_cluster_infrastructure_ecs_asg_diff_metric_lambda" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert ? 1 : 0

  name = "${local.resource_prefix}-ecs-cluster-infrastructure-ecs-asg-diff-metric"
  policy = templatefile(
    "${path.root}/policies/lambda-default.json.tpl",
    {
      region        = local.aws_region
      account_id    = local.aws_account_id
      function_name = "${local.resource_prefix_hash}-ecs-cluster-infrastructure-ecs-asg-diff-metric"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_cluster_infrastructure_ecs_asg_diff_metric_lambda" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert ? 1 : 0

  role       = aws_iam_role.ecs_cluster_infrastructure_ecs_asg_diff_metric_lambda[0].name
  policy_arn = aws_iam_policy.ecs_cluster_infrastructure_ecs_asg_diff_metric_lambda[0].arn
}

resource "aws_iam_policy" "ecs_cluster_infrastructure_ecs_asg_diff_metric_cloudwatch_put_metric_data_lambda" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert ? 1 : 0

  name = "${local.resource_prefix}-ecs-cluster-infrastructure-ecs-asg-diff-metric-cloudwatch-put-metric-data"
  policy = templatefile(
    "${path.root}/policies/cloudwatch-put-metric-data.json.tpl",
    {
      region     = local.aws_region
      account_id = local.aws_account_id
      namespaces = ["ECS"]
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_cluster_infrastructure_ecs_asg_diff_cloudwatch_metric_put_metric_data_lambda" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert ? 1 : 0

  role       = aws_iam_role.ecs_cluster_infrastructure_ecs_asg_diff_metric_lambda[0].name
  policy_arn = aws_iam_policy.ecs_cluster_infrastructure_ecs_asg_diff_metric_cloudwatch_put_metric_data_lambda[0].arn
}

resource "aws_iam_policy" "ecs_cluster_infrastructure_ecs_asg_diff_metric_ecs_describe_cluster_lambda" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert ? 1 : 0

  name = "${local.resource_prefix}-ecs-cluster-infrastructure-ecs-asg-diff-metric-ecs-describe-cluster"
  policy = templatefile(
    "${path.root}/policies/ecs-describe-cluster.json.tpl",
    {
      region        = local.aws_region
      account_id    = local.aws_account_id
      cluster_names = [local.infrastructure_ecs_cluster_name]
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_cluster_infrastructure_ecs_asg_diff_metric_ecs_describe_cluster_lambda" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert ? 1 : 0

  role       = aws_iam_role.ecs_cluster_infrastructure_ecs_asg_diff_metric_lambda[0].name
  policy_arn = aws_iam_policy.ecs_cluster_infrastructure_ecs_asg_diff_metric_ecs_describe_cluster_lambda[0].arn
}

resource "aws_iam_policy" "ecs_cluster_infrastructure_ecs_asg_diff_metric_asg_describe_asg_lambda" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert ? 1 : 0

  name = "${local.resource_prefix}-ecs-cluster-infrastructure-ecs-asg-diff-metric-asg-describe-asg"
  policy = templatefile(
    "${path.root}/policies/asg-describe-asg.json.tpl", {}
  )
}

resource "aws_iam_role_policy_attachment" "ecs_cluster_infrastructure_ecs_asg_diff_metric_asg_describe_asg_lambda" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert ? 1 : 0

  role       = aws_iam_role.ecs_cluster_infrastructure_ecs_asg_diff_metric_lambda[0].name
  policy_arn = aws_iam_policy.ecs_cluster_infrastructure_ecs_asg_diff_metric_asg_describe_asg_lambda[0].arn
}

resource "aws_iam_policy" "ecs_cluster_infrastructure_ecs_asg_diff_metric_kms_encrypt" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert && local.infrastructure_kms_encryption ? 1 : 0

  name = "${local.resource_prefix}-ecs-cluster-infrastructure-ecs-asg-diff-metric-kms-encrypt"
  policy = templatefile(
    "${path.root}/policies/kms-encrypt.json.tpl",
    { kms_key_arn = aws_kms_key.infrastructure[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_cluster_infrastructure_ecs_asg_diff_kms_encrypt" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert && local.infrastructure_kms_encryption ? 1 : 0

  role       = aws_iam_role.ecs_cluster_infrastructure_ecs_asg_diff_metric_lambda[0].name
  policy_arn = aws_iam_policy.ecs_cluster_infrastructure_ecs_asg_diff_metric_kms_encrypt[0].arn
}

data "archive_file" "ecs_cluster_infrastructure_ecs_asg_diff_metric_lambda" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert ? 1 : 0

  type        = "zip"
  source_dir  = "lambdas/ecs-asg-diff-metric"
  output_path = "lambdas/.zip-cache/ecs-asg-diff-metric.zip"
}

resource "aws_lambda_function" "ecs_cluster_infrastructure_ecs_asg_diff_metric" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert ? 1 : 0

  filename         = data.archive_file.ecs_cluster_infrastructure_ecs_asg_diff_metric_lambda[0].output_path
  function_name    = "${local.resource_prefix_hash}-ecs-cluster-infrastructure-ecs-asg-diff-metric"
  description      = "${local.resource_prefix} ECS Cluster Infrastructure Container Instance / ASG Instance Difference Metric"
  handler          = "function.lambda_handler"
  runtime          = "python3.11"
  role             = aws_iam_role.ecs_cluster_infrastructure_ecs_asg_diff_metric_lambda[0].arn
  source_code_hash = data.archive_file.ecs_cluster_infrastructure_ecs_asg_diff_metric_lambda[0].output_base64sha256
  memory_size      = 128
  package_type     = "Zip"
  timeout          = 900

  environment {
    variables = {
      ecsClusterName = local.infrastructure_ecs_cluster_name
      asgName        = aws_autoscaling_group.infrastructure_ecs_cluster[0].name
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_cluster_infrastructure_ecs_asg_diff_metric_lambda,
    aws_iam_role_policy_attachment.ecs_cluster_infrastructure_ecs_asg_diff_cloudwatch_metric_put_metric_data_lambda,
    aws_iam_role_policy_attachment.ecs_cluster_infrastructure_ecs_asg_diff_metric_ecs_describe_cluster_lambda,
    aws_iam_role_policy_attachment.ecs_cluster_infrastructure_ecs_asg_diff_kms_encrypt
  ]
}

resource "aws_cloudwatch_event_rule" "ecs_cluster_infrastructure_ecs_asg_diff_metric_1_min_cron" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert ? 1 : 0

  name                = "${local.resource_prefix_hash}-ecs-cluster-infrastructure-ecs-asg-diff-metric-1-min"
  description         = "Triggers the ${aws_lambda_function.ecs_cluster_infrastructure_ecs_asg_diff_metric[0].function_name} Lambda every 1 minute"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "ecs_cluster_infrastructure_ecs_asg_diff_metric_1_min_cron" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert ? 1 : 0

  rule      = aws_cloudwatch_event_rule.ecs_cluster_infrastructure_ecs_asg_diff_metric_1_min_cron[0].name
  target_id = "lambda"
  arn       = aws_lambda_function.ecs_cluster_infrastructure_ecs_asg_diff_metric[0].arn
}

resource "aws_lambda_permission" "ecs_cluster_infrastructure_ecs_asg_diff_metric_allow_cloudwatch_execution" {
  count = local.enable_infrastructure_ecs_cluster_ecs_asg_diff_alert ? 1 : 0

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_cluster_infrastructure_ecs_asg_diff_metric[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_cluster_infrastructure_ecs_asg_diff_metric_1_min_cron[0].arn
}
