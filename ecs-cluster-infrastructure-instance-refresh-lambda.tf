resource "aws_cloudwatch_log_group" "ecs_cluster_infrastructure_instance_refresh_lambda_log_group" {
  count = local.infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression != "" ? 1 : 0

  name              = "/aws/lambda/${local.resource_prefix_hash}-ecs-cluster-infrastructure-instance-refresh"
  kms_key_id        = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  retention_in_days = local.infrastructure_ecs_cluster_instance_refresh_lambda_log_retention
}

resource "aws_iam_role" "ecs_cluster_infrastructure_instance_refresh_lambda" {
  count = local.infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression != "" ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("ecs-cluster-infrastructure-instance-refresh-lambda"), 0, 6)}"
  description = "${local.resource_prefix}-ecs-cluster-infrastructure-instance-refresh-lambda"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["lambda.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "ecs_cluster_infrastructure_instance_refresh_lambda" {
  count = local.infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression != "" ? 1 : 0

  name = "${local.resource_prefix}-ecs-cluster-infrastructure-instance-refresh-lambda"
  policy = templatefile(
    "${path.root}/policies/lambda-default.json.tpl",
    {
      region        = local.aws_region
      account_id    = local.aws_account_id
      function_name = "${local.resource_prefix_hash}-ecs-cluster-infrastructure-instance-refresh"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_cluster_infrastructure_instance_refresh_lambda" {
  count = local.infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression != "" ? 1 : 0

  role       = aws_iam_role.ecs_cluster_infrastructure_instance_refresh_lambda[0].name
  policy_arn = aws_iam_policy.ecs_cluster_infrastructure_instance_refresh_lambda[0].arn
}

resource "aws_iam_policy" "ecs_cluster_infrastructure_instance_refresh_allow_instance_refresh" {
  count = local.infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression != "" ? 1 : 0

  name = "${local.resource_prefix}-ecs-cluster-infrastructure-instance-refresh-allow-instance-refresh"
  policy = templatefile(
    "${path.root}/policies/asg-instance-refresh.json.tpl",
    {
      asg_arns = jsonencode([aws_autoscaling_group.infrastructure_ecs_cluster[0].arn])
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_cluster_infrastructure_instance_refresh_allow_instance_refresh" {
  count = local.infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression != "" ? 1 : 0

  role       = aws_iam_role.ecs_cluster_infrastructure_instance_refresh_lambda[0].name
  policy_arn = aws_iam_policy.ecs_cluster_infrastructure_instance_refresh_allow_instance_refresh[0].arn
}

resource "aws_iam_policy" "ecs_cluster_infrastructure_instance_refresh_kms_encrypt" {
  count = local.infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression != "" && local.infrastructure_kms_encryption ? 1 : 0

  name = "${local.resource_prefix}-ecs-cluster-infrastructure-kinstance-refresh-kms-encrypt"
  policy = templatefile(
    "${path.root}/policies/kms-encrypt.json.tpl",
    { kms_key_arn = aws_kms_key.infrastructure[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_cluster_infrastructure_instance_refresh_kms_encrypt" {
  count = local.infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression != "" && local.infrastructure_kms_encryption ? 1 : 0

  role       = aws_iam_role.ecs_cluster_infrastructure_instance_refresh_lambda[0].name
  policy_arn = aws_iam_policy.ecs_cluster_infrastructure_instance_refresh_kms_encrypt[0].arn
}

data "archive_file" "ecs_cluster_infrastructure_instance_refresh_lambda" {
  count = local.infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression != "" ? 1 : 0

  type        = "zip"
  source_dir  = "lambdas/ecs-asg-instance-refresh"
  output_path = "lambdas/.zip-cache/ecs-asg-instance-refresh.zip"
}

resource "aws_lambda_function" "ecs_cluster_infrastructure_instance_refresh" {
  count = local.infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression != "" ? 1 : 0

  filename         = data.archive_file.ecs_cluster_infrastructure_instance_refresh_lambda[0].output_path
  function_name    = "${local.resource_prefix_hash}-ecs-cluster-infrastructure-instance-refresh"
  description      = "${local.resource_prefix} ECS Cluster Infrastructure Instance Refresh"
  handler          = "function.lambda_handler"
  runtime          = "python3.11"
  role             = aws_iam_role.ecs_cluster_infrastructure_instance_refresh_lambda[0].arn
  source_code_hash = data.archive_file.ecs_cluster_infrastructure_instance_refresh_lambda[0].output_base64sha256
  memory_size      = 128
  package_type     = "Zip"
  timeout          = 900

  environment {
    variables = {
      asgName = aws_autoscaling_group.infrastructure_ecs_cluster[0].name
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_cloudwatch_event_rule" "ecs_cluster_infrastructure_instance_refresh" {
  count = local.infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression != "" ? 1 : 0

  name                = "${local.resource_prefix}-ecs-instance-refresh"
  description         = "${local.resource_prefix} Trigger lambda ECS instance refresh"
  schedule_expression = local.infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression
}

resource "aws_cloudwatch_event_target" "ecs_cluster_infrastructure_instance_refresh" {
  count = local.infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression != "" ? 1 : 0

  rule = aws_cloudwatch_event_rule.ecs_cluster_infrastructure_instance_refresh[0].name
  arn  = aws_lambda_function.ecs_cluster_infrastructure_instance_refresh[0].arn
}

resource "aws_lambda_permission" "ecs_cluster_infrastructure_instance_refresh_allow_cloudwatch" {
  count = local.infrastructure_ecs_cluster_instance_refresh_lambda_schedule_expression != "" ? 1 : 0

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_cluster_infrastructure_instance_refresh[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_cluster_infrastructure_instance_refresh[0].arn
}
