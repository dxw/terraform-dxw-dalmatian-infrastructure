resource "aws_cognito_user_pool" "infrastructure" {
  for_each = local.infrastructure_cognito_user_pools

  name                = "${local.resource_prefix}-${each.key}"
  deletion_protection = each.value["deletion_protection"] ? "ACTIVE" : "INACTIVE"
  user_pool_tier      = each.value["threat_protection"] == "OFF" ? "ESSENTIALS" : "PLUS"

  username_attributes      = ["email"]
  auto_verified_attributes = []

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  password_policy {
    minimum_length                   = each.value["password_minimum_length"]
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = each.value["password_require_symbols"]
    temporary_password_validity_days = 7
  }

  dynamic "user_pool_add_ons" {
    for_each = each.value["threat_protection"] == "OFF" ? [] : [each.value["threat_protection"]]
    content {
      advanced_security_mode = user_pool_add_ons.value
    }
  }

  dynamic "schema" {
    for_each = each.value["custom_attributes"]
    content {
      name                = schema.key
      attribute_data_type = schema.value["type"]
      mutable             = schema.value["mutable"]
      required            = false

      dynamic "string_attribute_constraints" {
        for_each = schema.value["type"] == "String" ? [1] : []
        content {
          min_length = 0
          max_length = 2048
        }
      }

      dynamic "number_attribute_constraints" {
        for_each = schema.value["type"] == "Number" ? [1] : []
        content {
          min_value = 0
        }
      }
    }
  }

  # Cognito pool schema is immutable after creation. Without this, any later
  # change to custom_attributes would force a replacement and destroy users.
  lifecycle {
    ignore_changes = [schema]
  }
}

resource "aws_cognito_user_pool_client" "infrastructure" {
  for_each = merge([
    for pool_name, pool in local.infrastructure_cognito_user_pools : {
      for client_name, client in pool["clients"] : "${pool_name}_${client_name}" => merge(client, {
        pool_name   = pool_name
        client_name = client_name
      })
    }
  ]...)

  name         = "${local.resource_prefix_hash}-${each.value["pool_name"]}-${each.value["client_name"]}"
  user_pool_id = aws_cognito_user_pool.infrastructure[each.value["pool_name"]].id

  generate_secret     = each.value["generate_secret"]
  explicit_auth_flows = each.value["explicit_auth_flows"]

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
  access_token_validity  = each.value["access_token_validity_minutes"]
  id_token_validity      = each.value["id_token_validity_minutes"]
  refresh_token_validity = each.value["refresh_token_validity_days"]

  enable_token_revocation              = each.value["enable_token_revocation"]
  prevent_user_existence_errors        = "ENABLED"
  supported_identity_providers         = ["COGNITO"]
  allowed_oauth_flows_user_pool_client = false
}

resource "aws_iam_role" "infrastructure_cognito_user_pool_import" {
  for_each = local.infrastructure_cognito_user_pools

  name        = "${local.resource_prefix}-${each.key}-user-import"
  description = "Allows Cognito user import jobs for ${local.resource_prefix}-${each.key} to write CloudWatch Logs"
  assume_role_policy = templatefile(
    "${path.root}/policies/assume-roles/service-principle-standard.json.tpl",
    { services = jsonencode(["cognito-idp.amazonaws.com"]) }
  )
}

resource "aws_iam_policy" "infrastructure_cognito_user_pool_import" {
  for_each = local.infrastructure_cognito_user_pools

  name        = "${local.resource_prefix}-${substr(sha512("cognito-user-pool-import-${each.key}"), 0, 6)}"
  description = "${local.resource_prefix}-cognito-user-pool-import-${each.key}"
  policy = templatefile(
    "${path.root}/policies/cognito-user-import-logs.json.tpl",
    {
      log_group_arn_prefix = "arn:aws:logs:${local.aws_region}:${local.aws_account_id}:log-group:/aws/cognito/userpools/${aws_cognito_user_pool.infrastructure[each.key].id}/*"
    }
  )
}

resource "aws_iam_role_policy_attachment" "infrastructure_cognito_user_pool_import" {
  for_each = local.infrastructure_cognito_user_pools

  role       = aws_iam_role.infrastructure_cognito_user_pool_import[each.key].name
  policy_arn = aws_iam_policy.infrastructure_cognito_user_pool_import[each.key].arn
}
