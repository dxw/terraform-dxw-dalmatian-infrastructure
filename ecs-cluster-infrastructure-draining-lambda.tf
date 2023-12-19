resource "aws_cloudwatch_log_group" "ecs_cluster_infrastructure_draining_lambda_log_group" {
  count = local.infrastructure_ecs_cluster_draining_lambda_enabled ? 1 : 0

  name              = "/aws/lambda/${local.project_name}-ecs-cluster-infrastructure-draining"
  kms_key_id        = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  retention_in_days = local.infrastructure_ecs_cluster_draining_lambda_log_retention
}

resource "aws_iam_role" "ecs_cluster_infrastructure_draining_lambda" {
  count = local.infrastructure_ecs_cluster_draining_lambda_enabled ? 1 : 0

  name = "${local.project_name}-ecs-cluster-infrastructure-draining-lambda"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["lambda.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "ecs_cluster_infrastructure_draining_lambda" {
  count = local.infrastructure_ecs_cluster_draining_lambda_enabled ? 1 : 0

  name = "${local.project_name}-ecs-cluster-infrastructure-draining-lambda"
  policy = templatefile(
    "${path.root}/policies/lambda-default.json.tpl",
    {
      region        = local.aws_region
      account_id    = local.aws_account_id
      function_name = "${local.project_name}-ecs-cluster-infrastructure-draining"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_cluster_infrastructure_draining_lambda" {
  count = local.infrastructure_ecs_cluster_draining_lambda_enabled ? 1 : 0

  role       = aws_iam_role.ecs_cluster_infrastructure_draining_lambda[0].name
  policy_arn = aws_iam_policy.ecs_cluster_infrastructure_draining_lambda[0].arn
}

resource "aws_iam_policy" "ecs_cluster_infrastructure_draining_ecs_container_instance_state_update_lambda" {
  count = local.infrastructure_ecs_cluster_draining_lambda_enabled ? 1 : 0

  name = "${local.project_name}-ecs-cluster-infrastructure-ecs-container-instance-state-update"
  policy = templatefile(
    "${path.root}/policies/ecs-container-instance-state-update.json.tpl", {}
  )
}

resource "aws_iam_role_policy_attachment" "ecs_cluster_infrastructure_draining_ecs_container_instance_state_update_lambda" {
  count = local.infrastructure_ecs_cluster_draining_lambda_enabled ? 1 : 0

  role       = aws_iam_role.ecs_cluster_infrastructure_draining_lambda[0].name
  policy_arn = aws_iam_policy.ecs_cluster_infrastructure_draining_ecs_container_instance_state_update_lambda[0].arn
}

resource "aws_iam_policy" "ecs_cluster_infrastructure_draining_sns_publish_lambda" {
  count = local.infrastructure_ecs_cluster_draining_lambda_enabled ? 1 : 0

  name = "${local.project_name}-ecs-cluster-infrastructure-sns-publish"
  policy = templatefile(
    "${path.root}/policies/sns-publish.json.tpl",
    { sns_topic_arn = aws_sns_topic.infrastructure_ecs_cluster_autoscaling_lifecycle_termination[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_cluster_infrastructure_draining_sns_publish_lambda" {
  count = local.infrastructure_ecs_cluster_draining_lambda_enabled ? 1 : 0

  role       = aws_iam_role.ecs_cluster_infrastructure_draining_lambda[0].name
  policy_arn = aws_iam_policy.ecs_cluster_infrastructure_draining_sns_publish_lambda[0].arn
}

resource "aws_iam_policy" "ecs_cluster_infrastructure_draining_kms_encrypt" {
  count = local.infrastructure_ecs_cluster_draining_lambda_enabled && local.infrastructure_kms_encryption ? 1 : 0

  name = "${local.project_name}-ecs-cluster-infrastructure-kms-encrypt"
  policy = templatefile(
    "${path.root}/policies/kms-encrypt.json.tpl",
    { kms_key_arn = aws_kms_key.infrastructure[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_cluster_infrastructure_draining_kms_encrypt" {
  count = local.infrastructure_ecs_cluster_draining_lambda_enabled && local.infrastructure_kms_encryption ? 1 : 0

  role       = aws_iam_role.ecs_cluster_infrastructure_draining_lambda[0].name
  policy_arn = aws_iam_policy.ecs_cluster_infrastructure_draining_kms_encrypt[0].arn
}

data "archive_file" "ecs_cluster_infrastructure_draining_lambda" {
  count = local.infrastructure_ecs_cluster_draining_lambda_enabled ? 1 : 0

  type        = "zip"
  source_dir  = "lambdas/ecs-ec2-draining"
  output_path = "lambdas/.zip-cache/ecs-ec2-draining.zip"
}

resource "aws_lambda_function" "ecs_cluster_infrastructure_draining" {
  count = local.infrastructure_ecs_cluster_draining_lambda_enabled ? 1 : 0

  filename         = data.archive_file.ecs_cluster_infrastructure_draining_lambda[0].output_path
  function_name    = "${local.project_name}-ecs-cluster-infrastructure-draining"
  description      = "${local.project_name} ECS Cluster Infrastructure Draining"
  handler          = "function.lambda_handler"
  runtime          = "python3.11"
  role             = aws_iam_role.ecs_cluster_infrastructure_draining_lambda[0].arn
  source_code_hash = data.archive_file.ecs_cluster_infrastructure_draining_lambda[0].output_base64sha256
  memory_size      = 128
  package_type     = "Zip"
  timeout          = 900

  environment {
    variables = {
      ecsClusterName = local.infrastructure_ecs_cluster_name
      awsRegion      = local.aws_region
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "ecs_cluster_infrastructure_draining_allow_sns_execution" {
  count = local.infrastructure_ecs_cluster_draining_lambda_enabled ? 1 : 0

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_cluster_infrastructure_draining[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.infrastructure_ecs_cluster_autoscaling_lifecycle_termination[0].arn
}

resource "aws_sns_topic_subscription" "ecs_cluster_infrastructure_draining_autoscaling_lifecycle_termination" {
  count = local.infrastructure_ecs_cluster_draining_lambda_enabled ? 1 : 0

  topic_arn = aws_sns_topic.infrastructure_ecs_cluster_autoscaling_lifecycle_termination[0].arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.ecs_cluster_infrastructure_draining[0].arn
}
