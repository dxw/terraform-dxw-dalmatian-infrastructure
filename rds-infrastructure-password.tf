resource "random_password" "infrastructure_rds_root" {
  for_each = {
    for k, v in local.infrastructure_rds : k => v if v["type"] != null
  }

  length           = 16
  special          = true
  override_special = "_!%^"
}

resource "aws_secretsmanager_secret" "infrastructure_rds_root_password" {
  for_each = {
    for k, v in local.infrastructure_rds : k => v if v["type"] != null
  }

  name = "${local.resource_prefix_hash}/rds/root-password/${each.key}"
}

resource "aws_secretsmanager_secret_version" "infrastructure_rds_root_password" {
  for_each = {
    for k, v in local.infrastructure_rds : k => v if v["type"] != null
  }

  secret_id     = aws_secretsmanager_secret.infrastructure_rds_root_password[each.key].id
  secret_string = random_password.infrastructure_rds_root[each.key].result
}
