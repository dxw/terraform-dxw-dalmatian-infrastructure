resource "aws_cloudwatch_log_group" "lambda_custom_functions" {
  for_each = local.custom_lambda_functions

  name              = "/aws/lambda/${local.project_name}-${each.key}-custom-lambda"
  kms_key_id        = local.infrastructure_kms_encryption ? aws_kms_key.infrastructure[0].arn : null
  retention_in_days = each.value["log_retention"]
}

resource "aws_iam_role" "lambda_custom_functions" {
  for_each = local.custom_lambda_functions

  name        = "${local.resource_prefix_hash}-${substr(sha512("${each.key}-custom-lambda"), 0, 6)}"
  description = "${local.resource_prefix}-${each.key}-custom-lambda"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["lambda.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "lambda_custom_functions" {
  for_each = local.custom_lambda_functions

  name = "${local.resource_prefix}-${each.key}-custom-lambda"
  policy = templatefile(
    "${path.root}/policies/lambda-default.json.tpl",
    {
      region        = local.aws_region
      account_id    = local.aws_account_id
      function_name = "${local.project_name}-${each.key}-custom-lambda"
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_custom_functions" {
  for_each = local.custom_lambda_functions

  role       = aws_iam_role.lambda_custom_functions[0].name
  policy_arn = aws_iam_policy.lambda_custom_functions[0].arn
}

resource "aws_iam_policy" "lambda_custom_functions_additional" {
  for_each = {
    for k, custom_lambda in local.custom_lambda_functions : k => custom_lambda if custom_lambda["s3_function_store_policy_key"] != null
  }

  name   = "${local.resource_prefix}-${each.key}-custom-lambda-additional"
  policy = data.aws_s3_object.lambda_custom_functions_policy[each.key].body
}

resource "aws_iam_role_policy_attachment" "lambda_custom_functions_additional" {
  for_each = {
    for k, custom_lambda in local.custom_lambda_functions : k => custom_lambda if custom_lambda["s3_function_store_policy_key"] != null
  }

  role       = aws_iam_role.lambda_custom_functions[0].name
  policy_arn = aws_iam_policy.lambda_custom_functions_additional[0].arn
}

resource "aws_lambda_function" "custom" {
  for_each = local.custom_lambda_functions

  s3_bucket         = data.aws_s3_object.lambda_custom_functions[each.key].bucket
  s3_key            = data.aws_s3_object.lambda_custom_functions[each.key].key
  s3_object_version = data.aws_s3_object.lambda_custom_functions[each.key].version_id

  function_name = "${local.resource_prefix}-custom-${each.key}"
  description   = "${local.resource_prefix} Custom ${each.key}"
  handler       = each.value["handler"]
  runtime       = each.value["runtime"]
  role          = aws_iam_role.lambda_custom_functions[0].name
  memory_size   = each.value["memory"]
  package_type  = "Zip"
  timeout       = each.value["timeout"]

  environment {
    variables = each.value["environment_variables"]
  }

  dynamic "vpc_config" {
    for_each = each.value["launch_in_infrastructure_vpc"] == true ? [1] : []
    content {
      security_group_ids = [aws_security_group.custom_lambda[each.key].id]
      subnet_ids         = local.infrastructure_vpc_network_enable_private ? [for subnet in aws_subnet.infrastructure_private : subnet.id] : local.infrastructure_vpc_network_enable_public ? [for subnet in aws_subnet.infrastructure_public : subnet.id] : null
    }
  }

  tracing_config {
    mode = "Active"
  }
}
