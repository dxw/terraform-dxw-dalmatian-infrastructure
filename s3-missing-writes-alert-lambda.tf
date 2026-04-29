resource "aws_cloudwatch_log_group" "s3_missing_writes_alert_lambda_log_group" {
  count = local.enable_s3_missing_writes_alert ? 1 : 0

  name              = "/aws/lambda/${local.resource_prefix_hash}-s3-missing-writes-alert"
  kms_key_id        = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  retention_in_days = 14
}

resource "aws_iam_role" "s3_missing_writes_alert_lambda" {
  count = local.enable_s3_missing_writes_alert ? 1 : 0

  name        = "${local.resource_prefix}-${substr(sha512("s3-missing-writes-alert"), 0, 6)}"
  description = "${local.resource_prefix}-s3-missing-writes-alert"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["lambda.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "s3_missing_writes_alert_lambda" {
  count = local.enable_s3_missing_writes_alert ? 1 : 0

  name = "${local.resource_prefix}-s3-missing-writes-alert"
  policy = templatefile(
    "${path.root}/policies/lambda-default.json.tpl",
    {
      region        = local.aws_region
      account_id    = local.aws_account_id
      function_name = "${local.resource_prefix_hash}-s3-missing-writes-alert"
      vpc           = "false"
    }
  )
}

resource "aws_iam_role_policy_attachment" "s3_missing_writes_alert_lambda" {
  count = local.enable_s3_missing_writes_alert ? 1 : 0

  role       = aws_iam_role.s3_missing_writes_alert_lambda[0].name
  policy_arn = aws_iam_policy.s3_missing_writes_alert_lambda[0].arn
}

resource "aws_iam_policy" "s3_missing_writes_alert_cloudwatch_get_metric_data_lambda" {
  count = local.enable_s3_missing_writes_alert ? 1 : 0

  name = "${local.resource_prefix}-s3-missing-writes-alert-cloudwatch-get-metric-data"
  policy = templatefile(
    "${path.root}/policies/cloudwatch-get-metric-data.json.tpl",
    {}
  )
}

resource "aws_iam_role_policy_attachment" "s3_missing_writes_alert_cloudwatch_get_metric_data_lambda" {
  count = local.enable_s3_missing_writes_alert ? 1 : 0

  role       = aws_iam_role.s3_missing_writes_alert_lambda[0].name
  policy_arn = aws_iam_policy.s3_missing_writes_alert_cloudwatch_get_metric_data_lambda[0].arn
}

resource "aws_iam_policy" "s3_missing_writes_alert_slack_sns_publish_lambda" {
  count = local.enable_s3_missing_writes_alert && local.infrastructure_slack_sns_topic_in_use ? 1 : 0

  name = "${local.resource_prefix}-s3-missing-writes-alert-slack-sns-publish"
  policy = templatefile(
    "${path.root}/policies/sns-publish.json.tpl",
    { sns_topic_arn = data.aws_sns_topic.infrastructure_slack_sns_topic[0].arn }
  )
}

resource "aws_iam_role_policy_attachment" "s3_missing_writes_alert_slack_sns_publish_lambda" {
  count = local.enable_s3_missing_writes_alert && local.infrastructure_slack_sns_topic_in_use ? 1 : 0

  role       = aws_iam_role.s3_missing_writes_alert_lambda[0].name
  policy_arn = aws_iam_policy.s3_missing_writes_alert_slack_sns_publish_lambda[0].arn
}

resource "aws_iam_policy" "s3_missing_writes_alert_kms_encrypt" {
  count = local.enable_s3_missing_writes_alert && local.infrastructure_kms_encryption ? 1 : 0

  name = "${local.resource_prefix}-s3-missing-writes-alert-kms-encrypt"
  policy = templatefile(
    "${path.root}/policies/kms-encrypt.json.tpl",
    {
      kms_key_arn = jsonencode(distinct(compact(concat(
        [aws_kms_key.infrastructure[0].arn],
        local.infrastructure_slack_sns_topic_in_use ? [data.aws_kms_key.infrastructure_slack_sns_topic[0].arn] : []
      ))))
    }
  )
}

resource "aws_iam_role_policy_attachment" "s3_missing_writes_alert_kms_encrypt" {
  count = local.enable_s3_missing_writes_alert && local.infrastructure_kms_encryption ? 1 : 0

  role       = aws_iam_role.s3_missing_writes_alert_lambda[0].name
  policy_arn = aws_iam_policy.s3_missing_writes_alert_kms_encrypt[0].arn
}

data "archive_file" "s3_missing_writes_alert_lambda" {
  count = local.enable_s3_missing_writes_alert ? 1 : 0

  type        = "zip"
  source_dir  = "lambdas/s3-missing-writes-alert"
  output_path = "lambdas/.zip-cache/s3-missing-writes-alert.zip"
}

resource "aws_lambda_function" "s3_missing_writes_alert" {
  count = local.enable_s3_missing_writes_alert ? 1 : 0

  filename         = data.archive_file.s3_missing_writes_alert_lambda[0].output_path
  function_name    = "${local.resource_prefix_hash}-s3-missing-writes-alert"
  description      = "${local.resource_prefix} S3 Missing Writes Alert"
  handler          = "function.lambda_handler"
  runtime          = "python3.11"
  role             = aws_iam_role.s3_missing_writes_alert_lambda[0].arn
  source_code_hash = data.archive_file.s3_missing_writes_alert_lambda[0].output_base64sha256
  memory_size      = 128
  package_type     = "Zip"
  timeout          = 900

  environment {
    variables = {
      MONITORED_BUCKETS = jsonencode(compact(concat(
        [for k, v in local.custom_s3_buckets : aws_s3_bucket.custom[k].id if v.enable_missing_writes_alert == true],
        local.enable_infrastructure_rds_backup_to_s3 ? [aws_s3_bucket.infrastructure_rds_s3_backups[0].id] : [],
        var.external_s3_buckets_missing_writes_alert
      )))
      SLACK_SNS_TOPIC_ARN = local.infrastructure_slack_sns_topic_in_use ? data.aws_sns_topic.infrastructure_slack_sns_topic[0].arn : null
    }
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = [
    aws_iam_role_policy_attachment.s3_missing_writes_alert_lambda,
    aws_iam_role_policy_attachment.s3_missing_writes_alert_cloudwatch_get_metric_data_lambda,
    aws_iam_role_policy_attachment.s3_missing_writes_alert_slack_sns_publish_lambda,
    aws_iam_role_policy_attachment.s3_missing_writes_alert_kms_encrypt
  ]
}

resource "aws_cloudwatch_event_rule" "s3_missing_writes_alert_cron" {
  count = local.enable_s3_missing_writes_alert ? 1 : 0

  name                = "${local.resource_prefix_hash}-s3-missing-writes-alert-cron"
  description         = "Triggers the ${aws_lambda_function.s3_missing_writes_alert[0].function_name} Lambda daily at the configured schedule (${var.s3_missing_writes_alert_lambda_schedule_expression})"
  schedule_expression = var.s3_missing_writes_alert_lambda_schedule_expression
}

resource "aws_cloudwatch_event_target" "s3_missing_writes_alert_cron" {
  count = local.enable_s3_missing_writes_alert ? 1 : 0

  rule      = aws_cloudwatch_event_rule.s3_missing_writes_alert_cron[0].name
  target_id = "lambda"
  arn       = aws_lambda_function.s3_missing_writes_alert[0].arn
}

resource "aws_lambda_permission" "s3_missing_writes_alert_allow_cloudwatch_execution" {
  count = local.enable_s3_missing_writes_alert ? 1 : 0

  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_missing_writes_alert[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_missing_writes_alert_cron[0].arn
}

resource "aws_s3_bucket_metric" "external_missing_writes" {
  for_each = toset(var.external_s3_buckets_missing_writes_alert)

  bucket = each.value
  name   = "EntireBucket"
}
