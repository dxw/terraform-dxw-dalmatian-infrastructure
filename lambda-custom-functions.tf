resource "aws_cloudwatch_log_group" "lambda_custom_functions" {
  for_each = local.custom_lambda_functions

  name              = "/aws/lambda/${local.resource_prefix}-custom-lambda-${each.key}"
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
      vpc           = each.value["launch_in_infrastructure_vpc"] == true ? "true" : "false"
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_custom_functions" {
  for_each = local.custom_lambda_functions

  role       = aws_iam_role.lambda_custom_functions[each.key].name
  policy_arn = aws_iam_policy.lambda_custom_functions[each.key].arn
}

resource "aws_iam_policy" "lambda_custom_functions_custom_policies" {
  for_each = merge([
    for lambda_name, lambda in local.custom_lambda_functions : {
      for custom_policy_name, custom_policy in lambda["custom_policies"] : "${lambda_name}_${custom_policy_name}" => {
        custom_policy      = custom_policy
        lambda_name        = lambda_name
        custom_policy_name = custom_policy_name
      }
    }
  ]...)

  name        = "${local.resource_prefix}-${substr(sha512("${each.value["lambda_name"]}-custom-lambda-${each.value["custom_policy_name"]}"), 0, 6)}"
  description = "${local.resource_prefix}-${each.value["lambda_name"]}-custom-lambda-${each.value["custom_policy_name"]}-${each.value["custom_policy_name"]} ${each.value["custom_policy"]["description"]}"
  policy      = jsonencode(each.value["custom_policy"]["policy"])
}

resource "aws_iam_role_policy_attachment" "lambda_custom_functions_custom_policies" {
  for_each = merge([
    for lambda_name, lambda in local.custom_lambda_functions : {
      for custom_policy_name, custom_policy in lambda["custom_policies"] : "${lambda_name}_${custom_policy_name}" => {
        lambda_name = lambda_name
      }
    }
  ]...)

  role       = aws_iam_role.lambda_custom_functions[each.value["lambda_name"]].name
  policy_arn = aws_iam_policy.lambda_custom_functions[each.key].arn
}

data "archive_file" "lambda_custom_functions_default_zip" {
  for_each = local.custom_lambda_functions

  type        = "zip"
  source_dir  = "lambdas/custom-lambda-default"
  output_path = "lambdas/.zip-cache/custom-lambda-default-${each.key}.zip"
}

resource "aws_s3_object" "lambda_custom_functions_default_zip" {
  for_each = local.custom_lambda_functions

  bucket = aws_s3_bucket.lambda_custom_functions_store[0].id
  key    = each.value["function_zip_s3_key"]
  source = data.archive_file.lambda_custom_functions_default_zip[each.key].output_path
  etag   = filemd5(data.archive_file.lambda_custom_functions_default_zip[each.key].output_path)

  lifecycle {
    ignore_changes = [
      source,
      etag
    ]
  }
}

resource "aws_lambda_function" "custom" {
  for_each = local.custom_lambda_functions

  s3_bucket         = aws_s3_bucket.lambda_custom_functions_store[0].id
  s3_key            = aws_s3_object.lambda_custom_functions_default_zip[each.key].key
  s3_object_version = null

  function_name = "${local.resource_prefix}-custom-${each.key}"
  description   = "${local.resource_prefix} Custom ${each.key}"
  handler       = each.value["handler"]
  runtime       = each.value["runtime"]
  role          = aws_iam_role.lambda_custom_functions[each.key].arn
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
